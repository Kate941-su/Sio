//
//  File.swift
//
//
//  Created by KaitoKitaya on 2024/03/10.
//

import Foundation

protocol SioRepository {
  func get(
    path: String,
    data: Any?,
    queryParameters: [String: Any]?,
    cancelToken: CancelToken?,
    options: OptionProtcol?,
    onSendProgress: ProgressCallback?,
    onReceiveProgress: ProgressCallback?
  ) async throws -> Response

  func getUri(
    uri: URL,
    data: Any?,
    queryParameters: [String: Any]?,
    cancelToken: CancelToken?,
    options: OptionProtcol?,
    onSendProgress: ProgressCallback?,
    onReceiveProgress: ProgressCallback?
  ) async throws -> Response

  func post(
    path: String,
    data: Any?,
    queryParameters: [String: Any]?,
    cancelToken: CancelToken?,
    options: OptionProtcol?,
    onSendProgress: ProgressCallback?,
    onReceiveProgress: ProgressCallback?
  ) async throws -> Response

  func postUri(
    uri: URL,
    data: Any?,
    queryParameters: [String: Any]?,
    cancelToken: CancelToken?,
    options: OptionProtcol?,
    onSendProgress: ProgressCallback?,
    onReceiveProgress: ProgressCallback?
  ) async throws -> Response

  // TODO: Being able to lower ios 15.0
  @available(iOS 15.0, *)
  func download(
    path: String,
    cancelToken: CancelToken?,
    options: OptionProtcol?
  ) async throws -> (URL?, URLResponse?)

  // TODO: Being able to lower ios 15.0
  @available(iOS 15.0, *)
  func downloadUri(
    uri: URL,
    cancelToken: CancelToken?
  ) async throws -> (URL?, URLResponse?)

  // After v1?
  func upload(
    uri: URL,
    data: Any?,
    queryParameters: [String: Any]?,
    cancelToken: CancelToken?,
    options: OptionProtcol?,
    onSendProgress: ProgressCallback?
  ) async throws -> Response

  func request(
    uri: URL,
    options: OptionProtcol,
    requestMethod: RequestMethod,
    onSendProgress: ProgressCallback?,
    onReceiveProgress: ProgressCallback?
  ) async throws -> Response

  func encodeRequest(
    uri: URL,
    options: OptionProtcol,
    requestMethod: RequestMethod?
  ) throws -> URLRequest?

  func decodeResponse(
    options: OptionProtcol,
    data: Data,
    response: URLResponse
  ) throws -> Response
}
