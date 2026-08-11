defmodule Finsave.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :name, :string
      add :deleted_at, :utc_datetime

      timestamps()
    end

    create unique_index(:accounts, [:email], name: :accounts__email__uk)
  end
end
