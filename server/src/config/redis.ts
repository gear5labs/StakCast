import Redis from "ioredis";
import logger from "./logger";
import config from "./config";

interface RedisService {
	setCache: <T>(key: string, value: T, ttl?: number) => Promise<string | null>;
	getCache: <T>(key: string) => Promise<T | null>;
	deleteCache: (key: string) => Promise<number>;
	existsCache: (key: string) => Promise<boolean>;
	closeConnection: () => Promise<void>;
	isConnected: () => boolean;
}

class RedisClient implements RedisService {
	private static instance: RedisClient | null = null;
	private client: Redis | null = null;
	private isReady: boolean = false;

	private constructor() {
		this.initializeClient();
	}

	private initializeClient = (): void => {
		try {
			this.client = new Redis({
				host: config.db.redis.host,
				port: config.db.redis.port as number,
				...(config.db.redis.password ? { password: config.db.redis.password } : {}),
				retryStrategy: (times: number) => (times > 1 ? null : Math.min(times * 200, 2000)),
				connectTimeout: 10000,
				maxRetriesPerRequest: 1,
			});

			this.client.on("connect", () => {
				logger.info("Redis connected successfully");
				console.log("Redis connected successfully");
			});

			this.client.on("ready", () => {
				this.isReady = true;
				logger.info("Redis is ready to accept commands");
			});

			this.client.on("error", err => {
				this.isReady = false;
				if (err.stack?.includes("ECONNREFUSED")) {
					logger.error("Redis connection refused. Is the server running?");
				} else {
					logger.error("Redis error:", err);
				}
			});

			this.client.on("close", () => {
				this.isReady = false;
				logger.info("Redis connection closed");
			});

			this.client.on("reconnecting", () => {
				logger.info("Redis attempting to reconnect");
			});
		} catch (error) {
			logger.error("Failed to initialize Redis client:", error);
			this.client = null;
		}
	};

	public static getInstance = (): RedisClient => {
		if (!RedisClient.instance) {
			RedisClient.instance = new RedisClient();
		}
		return RedisClient.instance;
	};

	private getClient = (): Redis => {
		if (!this.client) {
			logger.error("Redis client is not initialized");
			throw new Error("Redis client is not available");
		}
		return this.client;
	};

	public isConnected = (): boolean => {
		return this.isReady && !!this.client;
	};

	// Set Cache with TTL
	public setCache = async <T>(key: string, value: T, ttl?: number): Promise<string | null> => {
		try {
			const client = this.getClient();
			const data = JSON.stringify(value);
			console.log(`Storing data in Redis with key: ${key}`, data);

			// If TTL is provided, use setex (with expiry)
			if (ttl) {
				return await client.setex(key, ttl, data);
			} else {
				return await client.set(key, data);
			}
		} catch (error) {
			logger.error(`Failed to set cache for key: ${key}`, error);
			return null;
		}
	};

	// Get Cache from Redis
	public getCache = async <T>(key: string): Promise<T | null> => {
		try {
			const client = this.getClient();

			// Ensure Redis client is ready
			if (!this.isReady) {
				logger.error("Redis client is not ready");
				return null;
			}

			const data = await client.get(key);
			if (!data) return null;

			// Parse and return the cached data
			try {
				console.log(`Retrieved data from Redis for key: ${key}`, data);
				return JSON.parse(data) as T;
			} catch (parseError) {
				logger.error(`Failed to parse cached data for key: ${key}`, parseError);
				return null;
			}
		} catch (error) {
			logger.error(`Failed to get cache for key: ${key}`, error);
			return null;
		}
	};

	// Delete Cache from Redis
	public deleteCache = async (key: string): Promise<number> => {
		try {
			const client = this.getClient();
			return await client.del(key);
		} catch (error) {
			logger.error(`Failed to delete cache for key: ${key}`, error);
			return 0;
		}
	};

	// Check if Cache Exists
	public existsCache = async (key: string): Promise<boolean> => {
		try {
			const client = this.getClient();
			return (await client.exists(key)) === 1;
		} catch (error) {
			logger.error(`Failed to check if key exists: ${key}`, error);
			return false;
		}
	};
	// Close Redis Connection
	public closeConnection = async (): Promise<void> => {
		if (this.client) {
			await this.client.quit();
			this.client = null;
			this.isReady = false;
			logger.info("Redis connection closed");
		}
	};
}

const redisService = RedisClient.getInstance();

export const redis = redisService;
export const { setCache, getCache, deleteCache, existsCache, closeConnection, isConnected } = redisService;