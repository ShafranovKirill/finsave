defmodule Finsave.Factory do
  use ExMachina.Ecto, repo: Finsave.Repo

  alias Finsave.Identity.Account

  def account_factory do
    %Account{
      email: sequence(:email, &"kirshafranov#{&1}@gmail.com"),
      password_hash: Argon2.hash_pwd_salt("Q1w2e3r4t5!")
    }
  end
end
