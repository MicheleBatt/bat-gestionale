class Membership < ApplicationRecord
  include MembershipsHelper

  # Relations
  # L'utente è cercato per indirizzo email dal form: la presenza è verificata da
  # user_exists?, che spiega all'utente cosa è andato storto meglio del messaggio
  # predefinito di belongs_to ("Utente deve esistere").
  belongs_to :user, optional: true
  belongs_to :organization

  # Validations
  validate :user_exists?
  validate :user_not_already_member?
  validates :role, presence: true
  enum role: ALL_MEMBERSHIP_ROLES.index_by(&:itself), _prefix: :role

  def username
    self.user.full_name
  end

  private

    # I messaggi sono aggiunti a :base perché descrivono la situazione per intero:
    # associati a un attributo verrebbero preceduti dal suo nome ("Utente Questo utente...")
    def user_exists?
      return if self.user.present?

      errors.add(:base, "Non è stato trovato a sistema alcun utente con l'indirizzo email specificato")
    end

    def user_not_already_member?
      return if self.user_id.blank? || self.organization_id.blank?

      altre_membership = Membership.where(user_id: self.user_id, organization_id: self.organization_id)
      altre_membership = altre_membership.where.not(id: self.id) if self.persisted?
      return unless altre_membership.exists?

      errors.add(:base, "Questo utente appartiene già all'organizzazione")
    end
end
