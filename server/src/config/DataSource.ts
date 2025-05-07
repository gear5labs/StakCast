import { DataSource } from "typeorm"
import config from "./config";
const AppDataSource = new DataSource({
    type: 'postgres',
    host: config.db.postgres.host,
    port: config.db.postgres.port as number,
    username: config.db.postgres.username,
    password: config.db.postgres.password,
    database: config.db.postgres.database,
})
AppDataSource.initialize()
    .then(() => {
        console.log("Postres set up successfully!")
    })
    .catch((err) => {
        console.error("Error during Data Source initialization", err)
    })
export default AppDataSource;