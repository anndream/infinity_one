defmodule OneChat.Repo.Migrations.CreateMute do
  use Ecto.Migration

  def change do
    create table(:muted, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)
      add :channel_id, references(:channels, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
    # create index(:muted, [:user_id])
    # create index(:muted, [:channel_id])
    create unique_index(:muted, [:user_id, :channel_id], name: :muted_user_id_channel_id_index)

  end
end
