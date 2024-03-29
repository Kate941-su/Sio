// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@available(iOS 13.0, macOS 12.0, *)
public struct Sio: SioRepository {

  let session: URLSession = {
    /// If you create not to cache on your device
    /// You have to implement configration type would be .ephemeral.
    let configration = URLSessionConfiguration.default
    return URLSession(configuration: configration)
  }()
  public var baseOptions: BaseOptions
  private let urlSessionTaskService: URLSessionTaskService

  public init(options: BaseOptions? = nil) {
    self.baseOptions = options ?? BaseOptions()
    urlSessionTaskService = URLSessionTaskService(session: session)
  }

  public func get(
    path: String,
    data: Any? = nil,
    queryParameters: [String: Any]? = nil,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil,
    onSendProgress: ProgressCallback? = nil,
    onReceiveProgress: ProgressCallback? = nil
  ) async throws -> Response {
    let baseUri: URL? = options?.baseURI ?? baseOptions.baseURI

    guard let uri = connectUri(baseUri: baseUri, path: path) else {
      throw SioError.inValidUrl(path: URL(string: path)!)
    }

    return try await request(
      uri: uri,
      options: options ?? baseOptions,
      requestMethod: .GET)
  }

  public func getUri(
    uri: URL,
    data: Any? = nil,
    queryParameters: [String: Any]? = nil,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil,
    onSendProgress: ProgressCallback? = nil,
    onReceiveProgress: ProgressCallback? = nil
  ) async throws -> Response {
    return try await request(uri: uri, options: options ?? baseOptions, requestMethod: .GET)
  }

  public func post(
    path: String,
    data: Any? = nil,
    queryParameters: [String: Any]? = nil,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil,
    onSendProgress: ProgressCallback? = nil,
    onReceiveProgress: ProgressCallback? = nil
  ) async throws -> Response {

    let baseUri: URL? = options?.baseURI ?? baseOptions.baseURI

    guard let uri = connectUri(baseUri: baseUri, path: path) else {
      throw SioError.inValidUrl(path: URL(string: path))
    }

    return try await request(
      uri: uri,
      options: options ?? baseOptions,
      requestMethod: .POST)
  }

  public func postUri(
    uri: URL,
    data: Any? = nil,
    queryParameters: [String: Any]? = nil,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil,
    onSendProgress: ProgressCallback? = nil,
    onReceiveProgress: ProgressCallback? = nil
  ) async throws -> Response {
    return try await request(
      uri: uri,
      options: options ?? baseOptions,
      requestMethod: .POST)
  }

  @available(iOS 15.0, *)
  public func download(
    path: String,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil
  ) async throws -> (URL?, URLResponse?) {
    let baseUri: URL? = options?.baseURI ?? baseOptions.baseURI

    guard let uri = connectUri(baseUri: baseUri, path: path) else {
      throw SioError.inValidUrl(path: URL(string: path))
    }

    return try await download(uri: uri)
  }

  @available(iOS 15.0, *)
  public func downloadUri(
    uri: URL,
    cancelToken: CancelToken? = nil
  ) async throws -> (URL?, URLResponse?) {
    return try await download(uri: uri)
  }

  // After v1?
  public func upload(
    uri: URL,
    data: Any? = nil,
    queryParameters: [String: Any]? = nil,
    cancelToken: CancelToken? = nil,
    options: OptionProtcol? = nil,
    onSendProgress: ProgressCallback? = nil
  ) async throws -> Response {
    fatalError()
  }

  private func connectUri(baseUri: URL?, path: String) -> URL? {
    guard let baseUri else {
      return URL(string: path)
    }
    if #available(iOS 16, macOS 13, *) {
      return baseUri.appending(path: path)
    } else {
      return baseUri.appendingPathComponent(path)
    }
  }

  func request(
    uri: URL,
    options: OptionProtcol,
    requestMethod: RequestMethod,
    onSendProgress: ProgressCallback? = nil,
    onReceiveProgress: ProgressCallback? = nil
  ) async throws -> Response {
    let finalOptions = getFinalOptions(requestOptions: options)
    guard
      let request = try encodeRequest(uri: uri, options: finalOptions, requestMethod: requestMethod)
    else {
      throw SioError.inValidUrl(path: uri)
    }
    var data: Data
    var response: URLResponse
    do {
      if #available(iOS 15.0, *) {
        urlSessionTaskService.onSendProgress = onSendProgress
        urlSessionTaskService.onReceiveProgress = onReceiveProgress
        (data, response) = try await session.data(for: request, delegate: urlSessionTaskService)
      } else {
        (data, response) = try await session.data(for: request)
      }
    } catch {
      throw SioError.couldNotConnectServer(uri: uri, error: error)
    }
    let sioResponse = try decodeResponse(options: finalOptions, data: data, response: response)
    return sioResponse
  }

  // download method is very clear and its simpleness makes me confortable, but delegate doesn't work
  // so I have to use `bytes` instead ....
  // https://forums.developer.apple.com/forums/thread/738541
  @available(iOS 15.0, *)
  func download(
    uri: URL
  ) async throws -> (URL?, URLResponse?) {
    do {
      return try await session.download(for: URLRequest(url: uri))
    } catch {
      throw SioError.couldNotConnectServer(uri: uri, error: error)
    }
  }

  func encodeRequest(uri: URL, options: OptionProtcol, requestMethod: RequestMethod?) throws
    -> URLRequest?
  {

    /// A Base URL Request Object.
    var request = URLRequest(url: uri)

    if let timeout = options.timeout {
      request.timeoutInterval = timeout
    }

    /// Handling Request Method
    if let requestMethod {
      switch requestMethod {
      case .GET:
        request.httpMethod = RequestMethod.GET.rawValue
      case .POST:
        request.httpMethod = RequestMethod.POST.rawValue
      case .PUT:
        request.httpMethod = RequestMethod.PUT.rawValue
      }
    } else {
      request.httpMethod = RequestMethod.GET.rawValue
    }

    /// Handling Request Body
    if let requestBody = options.body {
      request.httpBody = requestBody
    }

    /// Handling Request HTTP Header
    if let requestHeaders = options.requestHeader {
      requestHeaders.forEach {
        request.setValue($0.headerValue, forHTTPHeaderField: $0.headerField)
      }
    }

    /// Handling Request Query Parameters
    if let queryParameters = options.queryParameters {
      var urlComponetns = URLComponents(string: uri.absoluteString)!
      var res: [URLQueryItem] = []
      for (key, value) in queryParameters {
        res.append(URLQueryItem(name: key, value: value))
      }
      urlComponetns.queryItems = res
      request.url = urlComponetns.url
    }

    return request
  }

  func decodeResponse(options: OptionProtcol, data: Data, response: URLResponse) throws -> Response
  {
    let contentLength = response.expectedContentLength
    let mimeType = response.mimeType ?? ""

    guard let httpURLResponse: HTTPURLResponse = response as? HTTPURLResponse else {
      throw SioError.decodeError()
    }

    guard
      let statusCode: StatusCode = StatusCode.normalizeStatusCode(
        statusCode: httpURLResponse.statusCode)
    else {
      throw SioError.unknownStatusCode(statusCode: httpURLResponse.statusCode)
    }

    if statusCode.rawValue >= 400 && statusCode.rawValue < 500 {
      throw SioError.invalidStatus(statusCode: statusCode)
    } else if statusCode.rawValue >= 500 && statusCode.rawValue < 600 {
      throw SioError.invalidStatus(statusCode: statusCode)
    }

    // Date Format
    var date: Date?
    if let stringDate = httpURLResponse.allHeaderFields["Date"] as? String {
      date = DateFormatterWrapper.dateFormatter.date(from: stringDate)
    }

    return Response(
      data: data,
      statusCode: statusCode,
      mimeType: mimeType,
      date: date,
      contentLength: Int(contentLength),
      responseHeader: response
    )
  }

  /// Option has a priority.
  ///  1. RequestOption
  ///  2. BaseOption
  ///  If RequestOption has a non nil option field, this field would apply RequestOption's filed.
  ///  If the field is nil in RequestOption, the field of BaseOption would apply
  private func getFinalOptions(requestOptions: OptionProtcol) -> OptionProtcol {
    return BaseOptions(
      baseURI: requestOptions.baseURI ?? baseOptions.baseURI,
      path: requestOptions.path ?? baseOptions.path,
      body: requestOptions.body ?? baseOptions.body,
      queryParameters: requestOptions.queryParameters ?? baseOptions.queryParameters,
      requestHeader: requestOptions.requestHeader ?? baseOptions.requestHeader,
      responseType: requestOptions.responseType ?? baseOptions.responseType,
      cancelToken: requestOptions.cancelToken ?? requestOptions.cancelToken,
      mimeType: requestOptions.mimeType ?? requestOptions.mimeType,
      timeout: requestOptions.timeout ?? requestOptions.timeout
    )
  }
}
