//
//  ReportService.swift
//  eRouska
//
//  Created by Lukáš Foldýna on 03/07/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation
import ExposureNotification
import FirebaseStorage
import FirebaseAuth
import Alamofire
import Zip
import CryptoKit

protocol ReportServicing: class {

    func calculateHmacKey(keys: [ExposureDiagnosisKey], secret: Data) throws -> String

    typealias UploadKeysCallback = (Result<Bool, Error>) -> Void

    var isUploading: Bool { get }
    func uploadKeys(keys: [ExposureDiagnosisKey], verificationPayload: String, hmacSecret: Data, callback: @escaping UploadKeysCallback)

    typealias DownloadKeysCallback = (Result<[URL], Error>) -> Void

    var isDownloading: Bool { get }
    func downloadKeys(callback: @escaping DownloadKeysCallback) -> Progress

    typealias ConfigurationCallback = (Result<ENExposureConfiguration, Error>) -> Void
    func fetchExposureConfiguration(callback: @escaping ConfigurationCallback)

}

final class ReportService: ReportServicing {

    private let healthAuthority = "cz.covid19cz.erouska.dev"

    private let uploadURL = URL(string: "https://exposure-i5jzq6zlxq-ew.a.run.app/v1/publish")!

    private let downloadBaseURL = URL(string: "https://storage.googleapis.com/exposure-notification-export-ejjud/")!
    private var downloadDestinationURL: URL {
        let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = directoryURLs.first else {
            fatalError("No documents directory!")
        }
        return documentsURL
    }
    private let downloadIndex = "/index.txt"

    func calculateHmacKey(keys: [ExposureDiagnosisKey], secret: Data) throws -> String {
        // Sort by the key.
        let sortedKeys = keys.sorted { (lhs, rhs) -> Bool in
            lhs.keyData.base64EncodedString() < rhs.keyData.base64EncodedString()
        }

        // Build the cleartext.
        let perKeyClearText: [String] = sortedKeys.map { key in
            [key.keyData.base64EncodedString(),
             String(key.rollingStartNumber),
             String(key.rollingPeriod),
             String(key.transmissionRiskLevel)].joined(separator: ".")
        }
        let clearText = perKeyClearText.joined(separator: ",")

        guard let clearData = clearText.data(using: .utf8) else {
            throw ReportError.stringEncodingFailure
        }

        let hmacKey = SymmetricKey(data: secret)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: clearData, using: hmacKey)
        return authenticationCode.withUnsafeBytes { bytes in
            return Data(bytes)
        }.base64EncodedString()
    }
    
    private(set) var isUploading: Bool = false

    func uploadKeys(keys: [ExposureDiagnosisKey], verificationPayload: String, hmacSecret: Data, callback: @escaping UploadKeysCallback) {
        guard !isUploading else {
            callback(.failure(ReportError.alreadyRunning))
            return
        }
        isUploading = true

        func reportFailure(_ error: Error) {
            log("ReportService Upload error: \(error)")
            DispatchQueue.main.async {
                self.isUploading = false
                callback(.failure(error))
            }
            return
        }

        func reportSuccess() {
            log("ReportService Upload done")
            DispatchQueue.main.async {
                self.isUploading = false
                AppSettings.lastUploadDate = Date()
                callback(.success(true))
            }
        }

        let randomInt = Int.random(in: 0...100)
        let randomBase64 = Data.random(count: randomInt + 100).base64EncodedString()
        let report = Report(
            temporaryExposureKeys: keys,
            healthAuthority: healthAuthority,
            verificationPayload: verificationPayload,
            hmacKey: hmacSecret.base64EncodedString(),
            symptomOnsetInterval: nil,
            traveler: false,
            revisionToken: nil,
            padding: randomBase64
        )

        AF.request(uploadURL, method: .post, parameters: report, encoder: JSONParameterEncoder.default)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: ReportResult.self) { response in
                print("Response upload")
                debugPrint(response)
                switch response.result {
                case .success:
                    reportSuccess()
                case .failure(let error):
                    reportFailure(error)
                }
        }
    }

    private(set) var isDownloading: Bool = false

    func downloadKeys(callback: @escaping DownloadKeysCallback) -> Progress {
        let progress = Progress()

        guard !isDownloading else {
            callback(.failure(ReportError.alreadyRunning))
            return progress
        }
        isDownloading = true

        func reportFailure(_ error: Error) {
            log("ReportService Download error: \(error)")
            isDownloading = false
            callback(.failure(error))
        }

        func reportSuccess(_ reports: [URL]) {
            log("ReportService Download done")
            isDownloading = false
            callback(.success(reports))
        }

        let destinationURL = self.downloadDestinationURL
        let destination: DownloadRequest.Destination = { temporaryURL, response in
            let url = destinationURL.appendingPathComponent(response.suggestedFilename!)
            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }
        var downloads: [DownloadRequest] = []

        AF.request(downloadBaseURL.appendingPathComponent(downloadIndex), method: .get)
            .validate(statusCode: 200..<300)
            .responseString { [weak self] response in
                print("Response index")
                debugPrint(response)
                guard let self = self else { return }

                let dispatchGroup = DispatchGroup()
                var localURLResults: [Result<[URL], Error>] = []

                switch response.result {
                case let .success(result):
                    let remoteURLs = result.split(separator: "\n").compactMap { self.downloadBaseURL.appendingPathComponent(String($0)) }

                    for remoteURL in remoteURLs {
                        dispatchGroup.enter()

                        try? FileManager.default.removeItem(at: destinationURL.appendingPathComponent(remoteURL.lastPathComponent).deletingPathExtension())

                        let download = AF.download(remoteURL, to: destination)
                            .validate(statusCode: 200..<300)
                            .response { response in
                                print("Response file")
                                debugPrint(response)

                                switch response.result {
                                case .success(let downloadedURL):
                                    guard let downloadedURL = downloadedURL else {
                                        localURLResults.append(.failure(ReportError.noFile))
                                        break
                                    }
                                    do {
                                        let unzipDirectory = try Zip.quickUnzipFile(downloadedURL)
                                        let fileURLs = try FileManager.default.contentsOfDirectory(at: unzipDirectory, includingPropertiesForKeys: [], options: [.skipsHiddenFiles])
                                        localURLResults.append(.success(fileURLs))
                                    } catch {
                                        localURLResults.append(.failure(error))
                                    }
                                case .failure(let error):
                                    localURLResults.append(.failure(error))
                                }

                                if progress.isCancelled {
                                    downloads.forEach { $0.cancel() }
                                }
                                dispatchGroup.leave()
                        }
                        progress.addChild(download.downloadProgress, withPendingUnitCount: 1)
                        downloads.append(download)
                    }
                case let .failure(error):
                    DispatchQueue.main.async {
                        reportFailure(error)
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    if progress.isCancelled {
                        reportFailure(ReportError.cancelled)
                        return
                    }

                    var localURLs: [URL] = []
                    for result in localURLResults {
                        switch result {
                        case let .success(URLs):
                            localURLs.append(contentsOf: URLs)
                        case let .failure(error):
                            reportFailure(error)
                            return
                        }
                    }
                    reportSuccess(localURLs)
                }
        }

        return progress
    }

    func fetchExposureConfiguration(callback: @escaping ConfigurationCallback) {
        let dataFromServer = """
        {
        "minimumRiskScore": 0,
        "attenuationDurationThresholds": [50, 70],
        "attenuationLevelValues": [1, 2, 3, 4, 5, 6, 7, 8],
        "daysSinceLastExposureLevelValues": [1, 2, 3, 4, 5, 6, 7, 8],
        "durationLevelValues": [1, 2, 3, 4, 5, 6, 7, 8],
        "transmissionRiskLevelValues": [1, 2, 3, 4, 5, 6, 7, 8]
        }
        """.data(using: .utf8)!

        do {
            let codableExposureConfiguration = try JSONDecoder().decode(ExposureConfiguration.self, from: dataFromServer)
            let exposureConfiguration = ENExposureConfiguration()
            exposureConfiguration.minimumRiskScore = codableExposureConfiguration.minimumRiskScore
            exposureConfiguration.attenuationLevelValues = codableExposureConfiguration.attenuationLevelValues as [NSNumber]
            exposureConfiguration.daysSinceLastExposureLevelValues = codableExposureConfiguration.daysSinceLastExposureLevelValues as [NSNumber]
            exposureConfiguration.durationLevelValues = codableExposureConfiguration.durationLevelValues as [NSNumber]
            exposureConfiguration.transmissionRiskLevelValues = codableExposureConfiguration.transmissionRiskLevelValues as [NSNumber]
            exposureConfiguration.metadata = ["attenuationDurationThresholds": codableExposureConfiguration.attenuationDurationThresholds]
            callback(.success(exposureConfiguration))
        } catch {
            callback(.failure(error))
        }
    }

}
