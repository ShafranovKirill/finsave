defmodule Finsave.Identity do
  alias Finsave.Identity.{Accounts, Account}

  defdelegate get_account(id), to: Accounts
  defdelegate get_account_by_email(email), to: Accounts
  defdelegate create_account(attrs), to: Accounts
  defdelegate update_account(account, attrs), to: Accounts
  defdelegate soft_delete_account(account), to: Accounts
  defdelegate change_password(account, attrs), to: Accounts
  defdelegate authentificate(email, password), to: Accounts

  defdelegate email_regex(), to: Account
  defdelegate password_regex(), to: Account
end
