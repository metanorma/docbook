# frozen_string_literal: true

module Docbook
  module Services
    # Service classes for data generation
    SERVICES_DIR = "#{__dir__}/services".freeze

    autoload :TocGenerator, "#{SERVICES_DIR}/toc_generator"
    autoload :IndexGenerator, "#{SERVICES_DIR}/index_generator"
    autoload :NumberingService, "#{SERVICES_DIR}/numbering_service"
    autoload :ImageResolver, "#{SERVICES_DIR}/image_resolver"
    autoload :DocumentStats, "#{SERVICES_DIR}/document_stats"
    autoload :Linter, "#{SERVICES_DIR}/linter"
    autoload :ListOfGenerator, "#{SERVICES_DIR}/list_of_generator"
    autoload :CollectionManifestResolver, "#{SERVICES_DIR}/collection_manifest"
    autoload :Validator, "#{SERVICES_DIR}/validator"
    autoload :Formatter, "#{SERVICES_DIR}/formatter"
    autoload :ImageUtils, "#{SERVICES_DIR}/image_utils"
  end
end
