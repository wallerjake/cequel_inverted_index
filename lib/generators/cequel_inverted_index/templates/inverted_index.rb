# This file was automatically generated with Cequel Inverted Index Generator
module InvertedIndex
  extend ActiveSupport::Concern

  class InvalidQuery < RuntimeError; end

  included do
    raise "Must have column :target_ids" unless method_defined?(:target_ids)
  end

  module ClassMethods
    def add_to_index(key:, target_id:)
      return if key.blank?
      index = self[key]
      index.target_ids << target_id
      index.save
    end

    def remove_from_index(key:, target_id:)
      return if key.blank?
      index = self[key]
      index.target_ids.delete(target_id)
      index.save
    end

    def find_target_ids(query)
      raise LookupIndex::InvalidQuery unless query
      find(query).target_ids
    rescue Cequel::Record::RecordNotFound
      []
    end
  end
end
