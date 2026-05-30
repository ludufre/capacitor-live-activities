import { Component, NgZone } from '@angular/core';

import { FormsModule } from '@angular/forms';
import { IonicModule } from '@ionic/angular';
import { LiveActivities, LiveActivitiesOptions } from 'capacitor-live-activities';
import { FaIconComponent } from '@fortawesome/angular-fontawesome';

@Component({
  selector: 'app-flight-tracker',
  templateUrl: './flight-tracker.page.html',
  styleUrls: ['./flight-tracker.page.scss'],
  standalone: true,
  imports: [IonicModule, FormsModule, FaIconComponent],
})
export class FlightTrackerPage {
  activityId: string | null = null;

  constructor(private readonly ngZone: NgZone) {}

  async startActivity() {
    const options: LiveActivitiesOptions = {
      layout: {
        type: 'container',
        properties: [
          { direction: 'vertical' },
          { spacing: 16 },
          { padding: 16 },
          { backgroundColor: '#0A2C4F' },
          { cornerRadius: 16 },
        ],
        children: [
          {
            type: 'container',
            properties: [{ direction: 'horizontal' }, { insideAlignment: 'center' }],
            children: [
              {
                type: 'text',
                properties: [{ text: '{{fromCode}}' }, { fontSize: 18 }, { fontWeight: 'bold' }, { color: '#FFFFFF' }],
              },
              {
                type: 'image',
                properties: [{ systemName: 'airplane' }, { color: '#FFFFFF' }, { width: 24 }, { height: 24 }],
              },
              {
                type: 'text',
                properties: [{ text: '{{toCode}}' }, { fontSize: 18 }, { fontWeight: 'bold' }, { color: '#FFFFFF' }],
              },
              { type: 'spacer', properties: [] },
              {
                type: 'text',
                properties: [
                  { text: '{{flightNumber}}' },
                  { fontSize: 14 },
                  { fontWeight: 'medium' },
                  { color: '#A9B9CC' },
                ],
              },
            ],
          },
          {
            type: 'container',
            properties: [{ direction: 'horizontal' }, { insideAlignment: 'bottom' }],
            children: [
              {
                type: 'container',
                properties: [{ direction: 'vertical' }, { spacing: 4 }, { insideAlignment: 'leading' }],
                children: [
                  {
                    type: 'text',
                    properties: [{ text: 'STATUS' }, { fontSize: 10 }, { fontWeight: 'bold' }, { color: '#A9B9CC' }],
                  },
                  {
                    type: 'text',
                    properties: [
                      { text: '{{status}}' },
                      { fontSize: 16 },
                      { fontWeight: 'semibold' },
                      { color: '#FFFFFF' },
                    ],
                  },
                ],
              },
              { type: 'spacer', properties: [] },
              {
                type: 'container',
                properties: [{ direction: 'vertical' }, { spacing: 4 }, { insideAlignment: 'trailing' }],
                children: [
                  {
                    type: 'text',
                    properties: [{ text: 'GATE' }, { fontSize: 10 }, { fontWeight: 'bold' }, { color: '#A9B9CC' }],
                  },
                  {
                    type: 'text',
                    properties: [
                      { text: '{{gate}}' },
                      { fontSize: 16 },
                      { fontWeight: 'semibold' },
                      { color: '#FFFFFF' },
                    ],
                  },
                ],
              },
              {
                type: 'container',
                properties: [{ direction: 'vertical' }, { spacing: 4 }, { insideAlignment: 'trailing' }],
                children: [
                  {
                    type: 'text',
                    properties: [{ text: 'SEAT' }, { fontSize: 10 }, { fontWeight: 'bold' }, { color: '#A9B9CC' }],
                  },
                  {
                    type: 'text',
                    properties: [
                      { text: '{{seat}}' },
                      { fontSize: 16 },
                      { fontWeight: 'semibold' },
                      { color: '#FFFFFF' },
                    ],
                  },
                ],
              },
            ],
          },
          {
            type: 'progress',
            properties: [
              { value: '{{progress}}' },
              { total: 1.0 },
              { color: '#34C759' },
              { backgroundColor: '#FFFFFF30' },
              { height: 6 },
            ],
          },
        ],
      },
      dynamicIslandLayout: {
        expanded: {
          leading: {
            type: 'text',
            properties: [{ text: '{{fromCode}}' }, { fontSize: 14 }, { fontWeight: 'bold' }, { color: '#FFFFFF' }],
          },
          trailing: {
            type: 'text',
            properties: [{ text: '{{toCode}}' }, { fontSize: 14 }, { fontWeight: 'bold' }, { color: '#FFFFFF' }],
          },
          center: {
            type: 'container',
            properties: [{ direction: 'vertical' }, { spacing: 2 }, { insideAlignment: 'center' }],
            children: [
              {
                type: 'text',
                properties: [{ text: '{{status}}' }, { fontSize: 11 }, { fontWeight: 'medium' }, { color: '#A9B9CC' }],
              },
              {
                type: 'image',
                properties: [{ systemName: 'airplane' }, { color: '#FFFFFF' }, { width: 16 }, { height: 16 }],
              },
            ],
          },
          bottom: {
            type: 'progress',
            properties: [
              { value: '{{progress}}' },
              { total: 1.0 },
              { color: '#34C759' },
              { backgroundColor: '#FFFFFF30' },
              { height: 4 },
            ],
          },
        },
        compactLeading: {
          type: 'image',
          properties: [{ systemName: 'airplane' }, { color: '#FFFFFF' }, { width: 16 }, { height: 16 }],
        },
        compactTrailing: {
          type: 'text',
          properties: [{ text: 'Gate {{gate}}' }, { fontSize: 12 }, { fontWeight: 'semibold' }, { color: '#FFFFFF' }],
        },
        minimal: {
          type: 'image',
          properties: [{ systemName: 'airplane' }, { color: '#FFFFFF' }, { width: 16 }, { height: 16 }],
        },
      },
      data: {
        fromCode: 'SFO',
        toCode: 'JFK',
        flightNumber: 'UA456',
        status: 'Boarding',
        gate: 'A12',
        seat: '18C',
        progress: '0.1',
      },
      behavior: {
        widgetUrl: 'my-app://flight/UA456',
      },
    };

    const result = await LiveActivities.startActivity(options);

    this.ngZone.run(() => {
      this.activityId = result.activityId;
    });
  }

  async updateActivity() {
    await LiveActivities.updateActivity({
      activityId: this.activityId!,
      data: {
        status: 'In-Air',
        progress: '0.5',
      },
    });
  }

  async endActivity() {
    await LiveActivities.endActivity({
      activityId: this.activityId!,
      data: {
        status: 'Landed',
        progress: '1.0',
      },
    });
    this.ngZone.run(() => {
      this.activityId = null;
    });
  }
}
