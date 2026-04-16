# frozen_string_literal: true

module Docbook
  module Elements
    class ImageData < Lutaml::Model::Serializable
      attribute :fileref, :string
      attribute :format, :string
      attribute :width, :string
      attribute :depth, :string
      attribute :align, :string
      attribute :scalefit, :string
      attribute :contentwidth, :string
      attribute :contentdepth, :string

      xml do
        element "imagedata"
        map_attribute "fileref", to: :fileref
        map_attribute "format", to: :format
        map_attribute "width", to: :width
        map_attribute "depth", to: :depth
        map_attribute "align", to: :align
        map_attribute "scalefit", to: :scalefit
        map_attribute "contentwidth", to: :contentwidth
        map_attribute "contentdepth", to: :contentdepth
      end
    end
  end
end
