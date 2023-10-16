# frozen_string_literal: true

class Folio::Console::Boutique::Orders::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::IndexHelper

  def show
    @klass = Boutique::Order
    render
  end

  def additional_columns_proc
    # override in main app
    # Proc.new do |context, record|
    #   context.attribute(:foo) do
    #     record.bar
    #   end
    # end
  end

  def state_tooltip_proc
    # override in main app
    # Proc.new do |context, record|
    #   record.foo
    # end
  end
end
