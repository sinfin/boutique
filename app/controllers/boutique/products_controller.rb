# frozen_string_literal: true

class Boutique::ProductsController < Boutique::ApplicationController
  def show
    @product = Boutique::Product.friendly.find(params[:id])

    # If this is a social media crawler, render the template with meta tags
    if crawler_request?
      set_meta_variables(@product)
      @og_title = @product.og_title.presence || @product.title
      @og_image = @product.og_image.thumb(Folio::OG_IMAGE_DIMENSIONS).url if @product.og_image

      render :show
    else
      # For regular users, redirect to cart as before
      permitted_params = params.permit(permitted_params_keys).to_h.symbolize_keys
      redirect_to crossdomain_add_order_url(permitted_params.merge(product_slug: params[:id]))
    end
  end

  private
    def crawler_request?
      user_agent = request.user_agent.to_s.downcase

      # Check for common social media crawlers
      social_crawlers = [
        "facebookexternalhit",   # Facebook
        "twitterbot",            # Twitter/X
        "linkedinbot",           # LinkedIn
        "whatsapp",              # WhatsApp
        "slackbot",              # Slack
        "telegrambot",           # Telegram
        "discordbot",            # Discord
        "skypebot",              # Skype
        "pinterest",             # Pinterest
        "googlebot",             # Google
        "bingbot",               # Bing
        "applebot",              # Apple (for iMessage previews)
        "redditbot"              # Reddit
      ]

      social_crawlers.any? { |crawler| user_agent.include?(crawler) }
    end

    def permitted_params_keys
      [:subscription_id, Boutique::OrdersController::VOUCHER_GET_PARAM_NAME] + additional_permitted_params_keys
    end

    def additional_permitted_params_keys
      []
    end
end
