import { DataSource } from "typeorm"
import config from "./config";
import { User } from "../api/v1/User/user.entity";
import { Auth } from "../api/v1/Auth/auth.entity";
import { Market } from "../api/v1/market/market.entity";

const AppDataSource = new DataSource({
    type: 'postgres',
    host: config.db.postgres.host,
    port: config.db.postgres.port as number,
    username: config.db.postgres.username,
    password: config.db.postgres.password,
    database: config.db.postgres.database,
    entities: [User, Auth, Market],
    migrations: ["migrations/*.ts"],
    synchronize: false, //process.env.NODE_ENV !== 'production', // Auto-create database schema in development
    logging: process.env.NODE_ENV !== 'production',
})

AppDataSource.initialize()
    .then(() => {
        console.log("Postgres database initialized successfully!")
    })
    .catch((err) => {
        console.error("Error during Data Source initialization", err)
    })

export default AppDataSource;