# frozen_string_literal: true

module Docbook
  module Services
    # Service classes for data generation
    SERVICES_DIR = "#{__dir__}/services"

    autoload :TocGenerator, "#{SERVICES_DIR}/toc_generator"
    autoload :IndexGenerator, "#{SERVICES_DIR}/index_generator"
    autoload :NumberingService, "#{SERVICES_DIR}/numbering_service"
    autoload :ElementToHash, "#{SERVICES_DIR}/element_to_hash"
    autoload :DocumentBuilder, "#{SERVICES_DIR}/document_builder"
    autoload :ElementIdHelper, "#{SERVICES_DIR}/element_id_helper"
    autoload :ImageResolver, "#{SERVICES_DIR}/image_resolver"
  end
end
