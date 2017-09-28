class ApplicationJob < ActiveJob::Base
	include ActiveJob::Retriable
	max_retry 10
end
