class ServiceResult
  attr_reader :value, :error

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def self.capture
    success(yield)
  rescue StandardError => error
    failure(error)
  end

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  def error_message
    error&.message.presence || "Service failed"
  end
end
