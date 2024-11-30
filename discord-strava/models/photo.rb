class Photo
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user_activity

  field :unique_id, type: String
  field :urls, type: Hash
  field :source, type: Integer
  field :caption, type: String
  field :photo_created_at, type: DateTime
  field :photo_created_at_local, type: DateTime
  field :uploaded_at, type: DateTime
  field :sizes, type: Hash
  field :default_photo, type: Boolean

  def to_s
    "unique_id=#{unique_id}, default=#{default_photo}"
  end

  def has_image?
    !!image_url
  end

  def image_url
    urls&.values&.first
  end

  def to_discord_embed
    return unless has_image?

    embed = {}
    embed[:title] = caption.to_s if caption && !caption.blank?
    embed[:image] = { url: image_url }
    embed
  end

  def self.attrs_from_strava(response)
    {
      unique_id: response.unique_id,
      urls: response.urls,
      source: response.source,
      caption: response.caption,
      photo_created_at: response.created_at,
      photo_created_at_local: response.created_at_local,
      uploaded_at: response.uploaded_at,
      sizes: response.sizes,
      default_photo: response.default_photo
    }
  end

  alias eql? ==

  def ==(other)
    other.is_a?(Photo) &&
      unique_id == other.unique_id
  end
end