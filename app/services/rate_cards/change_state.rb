# Rate Cards list actions: Make Default, Archive, Unarchive.
# The default card can't be archived; nor can a card clients are assigned to, or the last active card.
module RateCards
  class ChangeState < ApplicationService
    ACTIONS = %w[make_default archive unarchive].freeze

    def initialize(card:, action:)
      @card = card
      @action = action.to_s
    end

    def call
      raise ArgumentError, "unknown action #{@action}" unless ACTIONS.include?(@action)

      RateCard.transaction { send(@action) }
      @card
    end

    private

    def make_default
      raise Error, "Unarchive the card before making it the default" if @card.archived?

      RateCard.where(default_card: true).where.not(id: @card.id).find_each { |c| c.update!(default_card: false) }
      @card.update!(default_card: true)
    end

    def archive
      raise Error, "Make another card the default before archiving this one" if @card.default_card?
      raise Error, "#{@card.name} is assigned to clients. Assign them another card first" if @card.clients.kept.exists?
      raise Error, "Keep at least one active card" unless RateCard.active.where.not(id: @card.id).exists?

      @card.update!(archived_at: Time.current)
    end

    def unarchive = @card.update!(archived_at: nil)
  end
end
