import { injectable } from "tsyringe";
import { mailQueue } from "../config/queueConfig";
import { EmailJobData } from "../types/emailJobs";
import { processMailJob } from "../queues/mailProcessor";

@injectable()
export default class QueueService {
	private static isInitialized = false;

	constructor() {
		if (!QueueService.isInitialized) {
			this.setupQueueProcessors();
			QueueService.isInitialized = true;
		}
	}

	private setupQueueProcessors() {
		// Process mail jobs
		mailQueue.process("email", 5, processMailJob); // Process up to 5 jobs concurrently

		// Queue event listeners for monitoring
		mailQueue.on("completed", job => {
			console.log(`Mail job ${job.id} completed successfully`);
		});

		mailQueue.on("failed", (job, err) => {
			console.error(`Mail job ${job.id} failed:`, err.message);
		});

		mailQueue.on("stalled", job => {
			console.warn(`Mail job ${job.id} stalled`);
		});
	}

	async addEmailJob(jobData: EmailJobData, options?: any) {
		return await mailQueue.add("email", jobData, {
			priority: jobData.type === "PASSWORD_RESET" ? 10 : 5, // Higher priority for password resets
			...options,
		});
	}

	async getQueueStats() {
		const waiting = await mailQueue.getWaiting();
		const active = await mailQueue.getActive();
		const completed = await mailQueue.getCompleted();
		const failed = await mailQueue.getFailed();

		return {
			waiting: waiting.length,
			active: active.length,
			completed: completed.length,
			failed: failed.length,
		};
	}
}
