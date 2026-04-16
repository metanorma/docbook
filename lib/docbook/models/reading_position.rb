# frozen_string_literal: true

module Docbook
  module Models
    # Reading Position - user's reading progress
    class ReadingPosition < Lutaml::Model::Serializable
      attribute :section_id, :string
      attribute :percentage, :float
      attribute :last_read_at, :string
      attribute :reading_mode, :string # scroll, page, chapter, reference
      attribute :scroll_position, :integer

      json do
        map "sectionId", to: :section_id
        map "percentage", to: :percentage
        map "lastReadAt", to: :last_read_at
        map "readingMode", to: :reading_mode
        map "scrollPosition", to: :scroll_position
      end
    end
  end
end
