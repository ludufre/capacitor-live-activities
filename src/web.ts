import { WebPlugin } from '@capacitor/core';

import type {
  EndActivityOptions,
  LiveActivitiesOptions,
  LiveActivitiesPlugin,
  UpdateActivityOptions,
} from './definitions';

export class LiveActivitiesWeb extends WebPlugin implements LiveActivitiesPlugin {
  startActivity(_: LiveActivitiesOptions): Promise<{ activityId: string, token: string }> {
    throw new Error('Method not implemented.');
  }
  updateActivity(_: UpdateActivityOptions): Promise<void> {
    throw new Error('Method not implemented.');
  }
  endActivity(_: EndActivityOptions): Promise<void> {
    throw new Error('Method not implemented.');
  }
  getAllActivities(): Promise<{ activities: LiveActivitiesOptions[] }> {
    throw new Error('Method not implemented.');
  }
  debugActivities(): Promise<{ activities: LiveActivitiesOptions[]; count: number }> {
    throw new Error('Method not implemented.');
  }
  saveImage(_: {
    imageData: string;
    name: string;
    compressionQuality?: number;
  }): Promise<{ success: boolean; imageName: string }> {
    throw new Error('Method not implemented.');
  }
  removeImage(_: { name: string }): Promise<{ success: boolean }> {
    throw new Error('Method not implemented.');
  }
  listImages(): Promise<{ images: string[] }> {
    throw new Error('Method not implemented.');
  }
  cleanupImages(): Promise<void> {
    throw new Error('Method not implemented.');
  }
}
