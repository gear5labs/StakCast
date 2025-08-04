import dotenv from "dotenv";
dotenv.config();
const environment = process.env.NODE_ENV || "development";

export const config = {
	port: process.env.PORT || 3678,
	NODE_ENV: environment,
	JWT: {
		accessToken: {
			secret: process.env.ACCESS_TOKEN_SECRET ?? "",
			exp: process.env.ACCESS_TOKEN_EXP ?? "30m",
		},
		refreshToken: {
			secret: process.env.REFRESH_TOKEN_SECRET ?? "",
			exp: process.env.REFRESH_TOKEN_EXP ?? "1w",
		},
	},
	db: {
		redis: {
			port: process.env.REDIS_PORT || 6379,
			host: process.env.REDIS_HOST || "localhost",
			password: process.env.REDIS_PASSWORD || undefined,
		},
		postgres: {
			port: process.env.POSTGRES_PORT || 5432, // Fixed: was POSTRES_PORT
			host: process.env.POSTGRES_HOST || "localhost",
			username: process.env.POSTGRES_USERNAME || "root",
			password: process.env.POSTGRES_PASSWORD || "",
			database: process.env.POSTGRES_DB_NAME || "stakcast",
		},
		// mongo_uri: getMongoUri() || "mongodb://localhost:27017/testdb",
	},
	email: {
		SMTP_HOST: process.env.EMAIL_SMTP_HOST?.trim(),
		user: process.env.EMAIL_USER?.trim(),
		password: process.env.EMAIL_PASS?.trim(),
		url: process.env.FRONTEND_URL?.trim() || "/",
	},
	starknet: {
		nodeUrl: process.env.NODE_URL?.trim(),
		accountClassHash:
			process.env.OZ_ACCOUNT_CLASS_HASH?.trim() || "0x540d7f5ec7ecf317e68d48564934cb99259781b1ee3cedbbc37ec5337f8e688",
	},
};

//template by solomonsolomonsolomon

export default config;
