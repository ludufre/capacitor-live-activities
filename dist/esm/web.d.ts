import { WebPlugin } from '@capacitor/core';
import type { EndActivityOptions, LiveActivitiesOptions, LiveActivitiesPlugin, UpdateActivityOptions } from './definitions';
export declare class LiveActivitiesWeb extends WebPlugin implements LiveActivitiesPlugin {
    startActivity(_: LiveActivitiesOptions): Promise<{
        activityId: string;
        token: string;
    }>;
    updateActivity(_: UpdateActivityOptions): Promise<void>;
    endActivity(_: EndActivityOptions): Promise<void>;
    getAllActivities(): Promise<{
        activities: LiveActivitiesOptions[];
    }>;
    debugActivities(): Promise<{
        activities: LiveActivitiesOptions[];
        count: number;
    }>;
    saveImage(_: {
        imageData: string;
        name: string;
        compressionQuality?: number;
    }): Promise<{
        success: boolean;
        imageName: string;
    }>;
    removeImage(_: {
        name: string;
    }): Promise<{
        success: boolean;
    }>;
    listImages(): Promise<{
        images: string[];
    }>;
    cleanupImages(): Promise<void>;
}
