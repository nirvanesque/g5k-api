if defined?(WebMock)
  WebMock.allow_net_connect! unless Rails.env == "test"
end