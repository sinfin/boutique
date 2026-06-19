# frozen_string_literal: true

class Folio::Console::Boutique::Subscriptions::Show::ButtonsCell < Folio::ConsoleCell
  def edit_button_options
    {
      href: url_for([:edit, :console, model]),
      variant: :secondary,
      icon: :edit,
      label: t("folio.console.actions.edit"),
    }
  end

  def cancel_button_options
    base = {
      variant: :danger,
      icon: :close,
      label: t("folio.console.boutique.subscriptions.catalogue.cancel"),
    }

    if cancellable?
      base.merge(href: url_for([:cancel, :console, model]),
                 method: :delete,
                 confirm: t("folio.console.boutique.subscriptions.catalogue.cancel_confirm"))
    else
      base.merge(disabled: true)
    end
  end

  def cancellable?
    model.recurrent? && !model.cancelled?
  end
end
