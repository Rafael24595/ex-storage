import Config

config :ex_storage,
  db_client: ExStorage.DB.SurrealDB.Client,
  work_serv: ExStorage.Core.Worker.WorkService,
  work_repo: ExStorage.DB.SurrealDB.WorkRepository
