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
		faucetAddress:
			process.env.FAUCET_ADDRESS?.trim() || "0x011745ee5409ea87e6ff22779a0d4cc7b53a71545e102a535107b650b7696896",
		faucetPK: process.env.FAUCET_PK?.trim() || "0x000000000000000000000000000000004a1b19d5dbb34b960b873d662a04f185",
		dripAmount: process.env.DRIP_AMOUNT?.trim() || "100000000000000000",
		strkToken: process.env.STRK_TOKEN?.trim() || "0x4718F5A0FC34CC1AF16A1CDEE98FFB20C31F5CD61D6AB07201858F4287C938D",
	},
};

//template by solomonsolomonsolomon

export const ADMIN_CONTRACT = {
  nodeUrl: process.env.NEXT_PUBLIC_RPC_URL || 'https://starknet-sepolia.public.blastapi.io',
  contractAddress: process.env.ADMIN_CONTRACT_ADDRESS || ''
};

export default config;
