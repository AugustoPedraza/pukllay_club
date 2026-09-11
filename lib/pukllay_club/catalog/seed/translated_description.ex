defmodule PukllayClub.Catalog.Seed.TranslatedDescription do
  @moduledoc """
  The InstructorLite response model for D-01's one-off Spanish translation
  job — the trust boundary between the Gemini API's answer and the
  database. An answer that does not shape-match this schema (missing the
  `description_es` field, or a non-string value) fails changeset
  validation and is never stored; `DescriptionTranslator` never trusts a
  raw HTTP response verbatim.

  `description_es` is named for its language explicitly so the prompt, the
  JSON schema `DescriptionTranslator` passes to the Gemini adapter, and
  this struct's own field all read consistently.
  """

  use Ecto.Schema
  use InstructorLite.Instruction

  @primary_key false
  embedded_schema do
    field :description_es, :string
  end

  @impl InstructorLite.Instruction
  def validate_changeset(changeset, _opts) do
    Ecto.Changeset.validate_required(changeset, [:description_es])
  end
end
