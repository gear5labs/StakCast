import Bull from "bull";
import Redis from "ioredis";
import config from "./config";

// Create Redis connection for Bull
const redisConfig = {
	port: config.db.redis.port as number,
	host: config.db.redis.host,
	password: config.db.redis.password,
	maxRetriesPerRequest: 3,
};

// Create mail queue
export const mailQueue = new Bull("mail queue", {
	redis: redisConfig,
	defaultJobOptions: {
		removeOnComplete: 10,
		removeOnFail: 5,
		attempts: 3,
		backoff: {
			type: "exponential",
			delay: 2000,
		},
	},
});

export default { mailQueue };
