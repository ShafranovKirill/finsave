defmodule Finsave.Identity.Accounts do
  alias Ecto.Repo
  alias Finsave.Identity.Account
  alias Finsave.{Repo}

  @spec get_account(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  def get_account(id) do
    case(Cachex.get(:account_cache, id)) do
      {:ok, nil} ->
        fetch_from_db_and_cache(id)

      {:ok, %Account{} = account} ->
        {:ok, account}
    end
  end

  @spec get_account_by_email(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  def get_account_by_email(email) do
    case Repo.get_by(Account, email: email) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @spec create_account(%{optional(:__struct__) => none(), optional(atom() | binary()) => any()}) ::
          any()
  def create_account(attrs) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Repo.insert()
  end

  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_account} ->
        Cachex.del(:account_cache, updated_account.id)
        {:ok, updated_account}

      error ->
        error
    end
  end

  @spec soft_delete_account(Account.t()) :: {:ok, Account.t() | {:error, Ecto.Changeset.t()}}
  def soft_delete_account(%Account{} = account) do
    account
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now(:second)})
    |> Repo.update()
    |> case do
      {:ok, deleted_account} ->
        Cachex.del(:account_cache, deleted_account.id)
        {:ok, deleted_account}

      error ->
        error
    end
  end

  @spec change_password(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def change_password(%Account{} = account, attrs) do
    account
    |> Account.update_password_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_account} ->
        Cachex.del(:account_cache, updated_account.id)
        {:ok, updated_account}

      error ->
        error
    end
  end

  @spec authentificate(String.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :invalid_credentials}
  def authentificate(email, password) do
    account = Repo.get_by(Account, email: email)

    if account do
      if Argon2.verify_pass(password, account.password_hash) do
        {:ok, account}
      else
        {:error, :invalid_credentials}
      end
    else
      Argon2.no_user_verify()
      {:error, :invalid_credentials}
    end
  end

  defp fetch_from_db_and_cache(id) do
    case Repo.get(Account, id) do
      nil ->
        {:error, :not_found}

      account ->
        cache_account(id, account)
        {:ok, account}
    end
  end

  defp cache_account(id, account) do
    Cachex.put(:account_cache, id, account, ttl: :timer.minutes(5))
  end
end
