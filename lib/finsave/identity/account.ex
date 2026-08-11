defmodule Finsave.Identity.Account do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: FinsaveWeb.Gettext

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {
    Flop.Schema,
    filterable: [:email],
    sortable: [:email, :inserted_at],
    default_limit: 10,
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  }

  schema "accounts" do
    field :email, :string
    field :password_hash, :string
    field :name, :string

    field :password, :string, virtual: true

    field :deleted_at, :utc_datetime
    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(account, attrs) do
    account
    |> cast(attrs, [
      :email,
      :password,
      :name
    ])
    |> validate_required([:email, :password])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_format(:password, password_regex())
    |> validate_format(:email, email_regex())
    |> downcase_email()
    |> unique_constraint(:email,
      name: :accounts__email__uk,
      message: dgettext_noop("errors", "This email is already in use.")
    )
    |> hash_password()
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(account, attrs) do
    account
    |> cast(attrs, [
      :name
    ])
    |> validate_length(:name, min: 3, max: 50)
  end

  @spec update_password_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_password_changeset(account, attrs) do
    account
    |> cast(attrs, [
      :password
    ])
    |> validate_required([:password])
    |> validate_format(:password, password_regex())
    |> hash_password()
  end

  @spec delete_changeset(t()) :: Ecto.Changeset.t()
  def delete_changeset(account) do
    change(account, %{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  @spec email_regex() :: Regex.t()
  @doc "Regular expression for validating email format"
  def email_regex, do: ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

  @spec password_regex() :: Regex.t()
  @doc "Regular expression for validating strong passwords"
  def password_regex, do: ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/

  @spec login_regex() :: Regex.t()
  @doc "Regular expression for validating login format"
  def login_regex, do: ~r/^[a-zA-Z0-9_.-]+$/

  defp downcase_email(changeset) do
    update_change(changeset, :email, &String.downcase/1)
  end

  @spec hash_password(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end
end
