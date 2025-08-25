import Config

config :ex_storage,
  db_client: ExStorage.DB.SurrealDB.Client,
  work_repo: ExStorage.DB.SurrealDB.Work
