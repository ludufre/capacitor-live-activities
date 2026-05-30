/**
 * Utility type to make complex types more readable in IntelliSense
 */
type Prettify<T> = {
  [K in keyof T]: Prettify<T[K]>;
} & NonNullable<unknown>;

/**
 * Main interface for Live Activity plugin functionality
 */
export interface LiveActivitiesPlugin {
  /**
   * Start a new Live Activity
   * @param options Configuration options for the Live Activity
   * @returns Promise with the generated activity ID
   */
  startActivity(options: LiveActivitiesOptions): Promise<{ activityId: string; token: string }>;

  /**
   * Update an existing Live Activity
   * @param options Update options including activity ID and new data
   * @returns Promise that resolves when update is complete
   */
  updateActivity(options: UpdateActivityOptions): Promise<void>;

  /**
   * End a Live Activity
   * @param options Options including activity ID and final data
   * @returns Promise that resolves when activity is ended
   */
  endActivity(options: EndActivityOptions): Promise<void>;

  /**
   * Get all active Live Activities
   * @returns Promise with array of all active activities
   */
  getAllActivities(): Promise<{ activities: LiveActivitiesOptions[] }>;

  /**
   * Save an image for use in Live Activities
   * @param options Image save options
   * @returns Promise with success status and image name
   */
  saveImage(options: {
    /** Base64 encoded image data */
    imageData: string;
    /** Name to save the image as */
    name: string;
    /** Compression quality (0-1), optional */
    compressionQuality?: number;
  }): Promise<{ success: boolean; imageName: string }>;

  /**
   * Remove a saved image
   * @param options Options with image name to remove
   * @returns Promise with success status
   */
  removeImage(options: { name: string }): Promise<{ success: boolean }>;

  /**
   * List all saved images
   * @returns Promise with array of image names
   */
  listImages(): Promise<{ images: string[] }>;

  /**
   * Clean up all saved images
   * @returns Promise that resolves when cleanup is complete
   */
  cleanupImages(): Promise<void>;
}

/**
 * Configuration options for starting a Live Activity
 */
export type LiveActivitiesOptions = {
  /** Layout configuration for the activity */
  layout: ActivityLayout;
  /** Dynamic Island layout configuration (optional) */
  dynamicIslandLayout: DynamicIslandLayout;
  /** Behavior configuration for the activity */
  behavior: LiveActivitiesBehavior;
  /** Dynamic data to be displayed in the activity */
  data: Record<string, any>;
  /** Date when the activity becomes stale (optional) */
  staleDate?: number;
  /** Relevance score for activity prioritization (optional) */
  relevanceScore?: number;
};

/**
 * Behavior configuration for a Live Activity
 * @category Configuration Types
 * @description Defines how the Live Activity behaves, including whether it should be pinned to the lock screen.
 */
export type LiveActivitiesBehavior = {
  /** @property widgetUrl - URL for the widget */
  widgetUrl: string;
  /** @property backgroundTint - Background color for the widget */
  backgroundTint?: ColorString;
  /** @property systemActionForegroundColor - Foreground color for system actions */
  systemActionForegroundColor?: ColorString;
  /** @property keyLineTint - Color for the key line */
  keyLineTint?: ColorString;
};

/**
 * Layout configuration for an activity
 * @category Configuration Types
 * @description The root layout element that defines the structure and appearance of a Live Activity.
 */
export type ActivityLayout = LayoutElement;

/**
 * Options for updating an existing Live Activity
 * @category Configuration Types
 * @description Configuration for updating an active Live Activity with new data and optional alert notifications.
 * @example
 * ```typescript
 * const updateOptions: UpdateActivityOptions = {
 *   activityId: "activity-123",
 *   data: { progress: 0.75, status: "In Progress" },
 *   alertConfiguration: {
 *     title: "Progress Update",
 *     body: "Task is 75% complete",
 *     sound: "default"
 *   }
 * };
 * ```
 */
export interface UpdateActivityOptions {
  /** ID of the activity to update */
  activityId: string;
  /** New data for the activity */
  data: Record<string, any>;
  /** Alert configuration for the update (optional) */
  alertConfiguration?: {
    /** Alert title */
    title: string;
    /** Alert body text */
    body: string;
    /** Sound to play with alert (optional) */
    sound?: string;
  };
}

/**
 * Options for ending a Live Activity
 * @category Configuration Types
 * @description Configuration for ending an active Live Activity with final data.
 * @example
 * ```typescript
 * const endOptions: EndActivityOptions = {
 *   activityId: "activity-123",
 *   data: { status: "Completed", finalResult: "Success" }
 * };
 * ```
 */
export interface EndActivityOptions {
  /** ID of the activity to end */
  activityId: string;
  /** Final data for the activity */
  data: Record<string, any>;
}

/**
 * Debug information about Live Activities
 * @category Data Types
 * @description Debugging information containing all active activities and their count.
 */

type ColorString =
  | 'primary'
  | 'secondary'
  | 'accent'
  | 'red'
  | 'blue'
  | 'green'
  | 'yellow'
  | 'orange'
  | 'purple'
  | 'pink'
  | 'black'
  | 'white'
  | 'gray'
  | 'clear'
  | `#${string}`;

/**
 * Union type representing any layout element with a unique ID
 * @category Layout Elements
 * @description Base type for all layout elements. Every element must have a unique ID and can be one of the supported element types.
 * @example
 * ```typescript
 * const element: LayoutElement = {
 *   type: "text",
 *   properties: [
 *     { text: "Hello World" }
 *   ]
 * };
 * ```
 */
export type LayoutElement = Prettify<
  | LayoutElementContainer
  | LayoutElementText
  | LayoutElementImage
  | LayoutElementProgress
  | LayoutElementTimer
  | LayoutElementChart
  | LayoutElementSegmentedProgress
  | LayoutElementSpacer
  | LayoutElementGauge
>;

/**
 * Base properties that all layout elements can have as individual objects
 * @category Property Objects
 * @description These properties are available for all layout element types and handle basic positioning, transformations, sizing, and visual effects.
 */
type BasePropertyObject =
  // Positioning
  /** @property offset - Position offset as coordinates or template string @example { offset: { x: 10, y: 20 } } */
  | { offset: { x?: number; y?: number } }
  /** @property zIndex - Z-index for layering @example { zIndex: 1 } */
  | { zIndex: number }

  // Transformations
  /** @property opacity - Opacity value (0-1) @example { opacity: 0.8 } */
  | { opacity: number }
  /** @property rotation - Rotation in degrees @example { rotation: 45 } */
  | { rotation: number }
  /** @property scale - Scale factor (1 = normal size) @example { scale: 1.2 } */
  | { scale: number }

  // Frame
  /** @property width - Element width @example { width: 100 } */
  | { width: number }
  /** @property height - Element height (-1 means Full) @example { height: 50 } */
  | { height: number }
  /** @property maxWidth - Maximum width constraint (-1 means Full) @example { maxWidth: 200 } */
  | { maxWidth: number }
  /** @property maxHeight - Maximum height constraint (-1 means Full) @example { maxHeight: 100 } */
  | { maxHeight: number }
  /** @property minWidth - Minimum width constraint (-1 means Full) @example { minWidth: 50 } */
  | { minWidth: number }
  /** @property minHeight - Minimum height constraint (-1 means Full) @example { minHeight: 25 } */
  | { minHeight: number }
  /** @property idealWidth - Ideal width for the element @example { idealWidth: 150 } */
  | { idealWidth: number }
  /** @property idealHeight - Ideal height for the element @example { idealHeight: 75 } */
  | { idealHeight: number }
  /** @property backgroundGradient - Gradient background configuration @example { backgroundGradient: { colors: ["#ff0000", "#0000ff"], startPoint: "top", endPoint: "bottom" } } */
  | { backgroundGradient: { colors: ColorString[]; startPoint: GradientPoint; endPoint: GradientPoint } }
  /** @property backgroundCapsule - Background capsule style @example { backgroundCapsule: { foregroundColor: "#ffffff" } } */
  | { backgroundCapsule: { foregroundColor: ColorString } }
  /** @property paddingVertical - Vertical padding @example { paddingVertical: 12 } */
  | { paddingVertical: number }
  /** @property paddingHorizontal - Horizontal padding @example { paddingHorizontal: 16 } */
  | { paddingHorizontal: number }
  /** @property multilineTextAlignment - Text alignment for multiline text @example { multilineTextAlignment: "center" } */
  | { multilineTextAlignment: 'leading' | 'center' | 'trailing' | 'left' | 'right' }
  /** @property padding - Padding inside the container @example { padding: 16 } */
  | { padding: number | boolean }

  // Effects
  /** @property shadow - Shadow configuration @example { shadow: { color: "#000000", radius: 5, x: 2, y: 2 } } */
  | { shadow: { color?: ColorString; radius?: number; x?: number; y?: number } };

/**
 * Container-specific property objects
 * @category Property Objects
 * @description Properties specific to container elements, including layout direction, spacing, styling, and background effects.
 * @extends xxx
 */
type ContainerPropertyObject =
  | (BasePropertyObject | ContainerPropertyObjectBase | ContainerPropertyObjectVertical)[]
  | (BasePropertyObject | ContainerPropertyObjectBase | ContainerPropertyObjectHorizontal)[]
  | (BasePropertyObject | ContainerPropertyObjectBase | ContainerPropertyObjectStack)[];

type ContainerPropertyObjectBase =
  /** @property spacing - Spacing between child elements @example { spacing: 12 } */
  | { spacing: number }
  /** @property foregroundColor - Foreground color style of container @example { foregroundColor: "#ffffff" } */
  | { foregroundColor: ColorString }
  /** @property backgroundColor - Background color of the container @example { backgroundColor: "#000000" } */
  | { backgroundColor: ColorString }
  /** @property cornerRadius - Corner radius for rounded corners @example { cornerRadius: 8 } */
  | { cornerRadius: number }
  /** @property borderWidth - Border width @example { borderWidth: 2 } */
  | { borderWidth: number }
  /** @property borderColor - Border color @example { borderColor: "#cccccc" } */
  | { borderColor: ColorString }
  /** @property alignment - Frame alignment within the container @example { alignment: "center" } */
  | { alignment: ContainerPropertyObjectStackAlignment };

type ContainerPropertyObjectHorizontal =
  /** @property direction - Container layout direction @example { direction: "horizontal" / HStack } */
  | { direction: 'horizontal' }
  /** @property insideAlignment - Vertical alignment within container @example { insideAlignment: "center" } */
  | { insideAlignment: 'bottom' | 'center' | 'first-text-baseline' | 'last-text-baseline' | 'top' };

type ContainerPropertyObjectVertical =
  /** @property direction - Container layout direction @example { direction: "vertical" / VStack } */
  | { direction: 'vertical' }
  /** @property insideAlignment - Horizontal alignment within container @example { insideAlignment: "center" } */
  | {
      insideAlignment:
        | 'center'
        | 'leading'
        | 'left'
        | 'list-row-separator-leading'
        | 'list-row-separator-trailing'
        | 'list-row-separator-left'
        | 'list-row-separator-right'
        | 'trailing'
        | 'right';
    };

type ContainerPropertyObjectStackAlignment =
  | 'top'
  | 'top-leading'
  | 'top-trailing'
  | 'top-left'
  | 'top-right'
  | 'bottom'
  | 'bottom-left'
  | 'bottom-right'
  | 'center'
  | 'center-first-text-baseline'
  | 'center-last-text-baseline'
  | 'leading'
  | 'leading-first-text-baseline'
  | 'leading-last-text-baseline'
  | 'left'
  | 'left-first-text-baseline'
  | 'left-last-text-baseline'
  | 'trailing'
  | 'trailing-first-text-baseline'
  | 'trailing-last-text-baseline'
  | 'right'
  | 'right-first-text-baseline'
  | 'right-last-text-baseline';

type ContainerPropertyObjectStack =
  /** @property direction - Container layout direction @example { direction: "stack" / ZStack } */
  | { direction: 'stack' }
  /** @property alignment - Alignment within container @example { alignment: "center" } */
  | {
      insideAlignment: ContainerPropertyObjectStackAlignment;
    };
/**
 * Text-specific property objects
 * @category Property Objects
 * @description Properties specific to text elements, including content, typography, styling, and text formatting options.
 * @extends BasePropertyObject
 */
type TextPropertyObject =
  | BasePropertyObject
  /** @property text - Text content to display @example { text: "Hello World" } */
  | { text: string }
  /** @property fontSize - Font size @example { fontSize: 16 } */
  | { fontSize: number }
  /** @property fontWeight - Font weight @example { fontWeight: "bold" } */
  | { fontWeight: 'regular' | 'medium' | 'semibold' | 'bold' | 'heavy' | 'light' | 'thin' | 'black' }
  /** @property fontFamily - Font family name @example { fontFamily: "Helvetica" } */
  | {
      fontFamily:
        | 'caption'
        | 'title'
        | 'headline'
        | 'body'
        | 'callout'
        | 'caption2'
        | 'footnote'
        | 'largeTitle'
        | 'subheadline'
        | 'title2'
        | 'title3';
    }
  /** @property color - Text color @example { color: "#333333" } */
  | { color: ColorString }
  /** @property alignment - Text alignment @example { alignment: "center" } */
  | { alignment: 'leading' | 'center' | 'trailing' | 'left' | 'right' }
  /** @property lineLimit - Maximum number of lines @example { lineLimit: 2 } */
  | { lineLimit: number }
  /** @property italic - Whether text is italic @example { italic: true } */
  | { italic: boolean }
  /** @property underline - Whether text is underlined @example { underline: true } */
  | { underline: boolean }
  /** @property strikethrough - Whether text has strikethrough @example { strikethrough: false } */
  | { strikethrough: boolean }
  /** @property monospacedDigit - Whether to use monospaced digits @example { monospacedDigit: true } */
  | { monospacedDigit: boolean };

/**
 * Image-specific property objects
 * @category Property Objects
 * @description Properties specific to image elements, including display options, source configuration, and image styling.
 * @extends BasePropertyObject
 */
type ImagePropertyObject =
  | BasePropertyObject
  /** @property contentMode - How the image should fit within its bounds @example { contentMode: "fit" } */
  | { contentMode: 'fit' | 'fill' }
  /** @property cornerRadius - Corner radius for rounded image corners @example { cornerRadius: 12 } */
  | { cornerRadius: number }
  /** @property systemName - SF Symbols system name @example { systemName: "heart.fill" } */
  | { systemName: string }
  /** @property color - Color tint for SF Symbols @example { color: "#ff0000" } */
  | { color: ColorString }
  /** @property url - Remote image URL @example { url: "https://example.com/image.jpg" } */
  | { url: string }
  /** @property appGroup - App Group container identifier for saved images @example { appGroup: "group.com.example.app" } */
  | { appGroup: string }
  /** @property asset - Asset name from app bundle @example { asset: "logo" } */
  | { asset: string }
  /** @property base64 - Base64 encoded image data @example { base64: "iVBORw0KGgoAAAANSUhEUgAA..." } */
  | { base64: string }
  /** @property resizable - Whether the image is resizable @example { resizable: true } */
  | { resizable: boolean };

/**
 * Progress-specific property objects
 * @category Property Objects
 * @description Properties specific to progress bar elements, including value configuration, styling, and appearance options.
 * @extends BasePropertyObject
 */
type ProgressPropertyObject =
  | BasePropertyObject
  /** @property value - Current progress value @example { value: 0.7 } */
  | { value: number | string }
  /** @property total - Total/maximum value for progress calculation @example { total: 100 } */
  | { total: number | string }
  /** @property color - Progress bar fill color @example { color: "#00ff00" } */
  | { color: ColorString }
  /** @property backgroundColor - Progress bar background color @example { backgroundColor: "#f0f0f0" } */
  | { backgroundColor: ColorString }
  /** @property height - Height of the progress bar @example { height: 8 } */
  | { height: number };

/**
 * Timer-specific property objects
 * @category Property Objects
 * @description Properties specific to timer elements, including time configuration, display style, and formatting options.
 * @extends BasePropertyObject
 */
type TimerPropertyObject =
  | TextPropertyObject
  /** @property endTime - End time as timestamp in milliseconds @example { endTime: 1749337396616 } */
  | { endTime: number }
  /** @property style - Timer display style @example { style: "timer" } */
  | { style: 'timer' | 'relative' | 'date' | 'time' | 'offset' | 'countdown' };

/**
 * Container element that can hold other layout elements
 * @category Layout Elements
 * @description A container element that organizes child elements in various layouts (vertical, horizontal, or stack).
 * Containers support spacing, padding, backgrounds, borders, and gradients.
 * @example
 * ```typescript
 * const container: LayoutElementContainer = {
 *   type: "container",
 *   properties: [
 *     { direction: "vertical" },
 *     { spacing: 12 },
 *     { padding: 16 },
 *     { backgroundColor: "#f0f0f0" }
 *   ],
 *   children: [textElement, imageElement]
 * };
 * ```
 */
export type LayoutElementContainer = Prettify<{
  /** Element type identifier */
  type: 'container';
  /** Container properties as array of property objects */
  properties?: ContainerPropertyObject;
  /** Child elements contained within this container */
  children: LayoutElement[];
}>;

/**
 * Background Gradient point options for defining gradient direction
 * @category Enums
 * @description Predefined points for gradient start and end positions.
 * @example
 * ```typescript
 * const backgroundGradient = {
 *   colors: ["#ff0000", "#0000ff"],
 *   startPoint: "top" as GradientPoint,
 *   endPoint: "bottom" as GradientPoint
 * };
 * ```
 */
type GradientPoint =
  /** @option top - Top edge */
  | 'top'
  /** @option bottom - Bottom edge */
  | 'bottom'
  /** @option leading - Leading edge (left in LTR, right in RTL) */
  | 'leading'
  /** @option trailing - Trailing edge (right in LTR, left in RTL) */
  | 'trailing'
  /** @option topLeading - Top-left corner */
  | 'topLeading'
  /** @option topTrailing - Top-right corner */
  | 'topTrailing'
  /** @option bottomLeading - Bottom-left corner */
  | 'bottomLeading'
  /** @option bottomTrailing - Bottom-right corner */
  | 'bottomTrailing'
  /** @option center - Center point */
  | 'center';

/**
 * Text element for displaying text content
 * @category Layout Elements
 * @description A text element for displaying styled text with typography controls, alignment, and formatting options.
 * @example
 * ```typescript
 * const textElement: LayoutElementText = {
 *   type: "text",
 *   properties: [
 *     { text: "Welcome to Live Activities" },
 *     { fontSize: 18 },
 *     { fontWeight: "bold" },
 *     { color: "#333333" },
 *     { alignment: "center" }
 *   ]
 * };
 * ```
 */
export type LayoutElementText = Prettify<{
  /** Element type identifier */
  type: 'text';
  /** Text properties as array of property objects */
  properties: TextPropertyObject[];
}>;

/**
 * Image element for displaying images from various sources
 * @category Layout Elements
 * @description An image element that can display images from URLs, SF Symbols, app assets, base64 data, or saved images.
 * @example
 * ```typescript
 * const imageElement: LayoutElementImage = {
 *   type: "image",
 *   properties: [
 *     { url: "https://example.com/avatar.jpg" },
 *     { contentMode: "fit" },
 *     { cornerRadius: 25 },
 *     { width: 50 },
 *     { height: 50 }
 *   ]
 * };
 * ```
 */
export type LayoutElementImage = Prettify<{
  /** Element type identifier */
  type: 'image';
  /** Image properties as array of property objects */
  properties: ImagePropertyObject[];
}>;

/**
 * Progress bar element for showing completion progress
 * @category Layout Elements
 * @description A progress bar element for visualizing completion status with customizable styling and values.
 * @example
 * ```typescript
 * const progressElement: LayoutElementProgress = {
 *   type: "progress",
 *   properties: [
 *     { value: 0.75 },
 *     { total: 1.0 },
 *     { color: "#00ff00" },
 *     { backgroundColor: "#cccccc" },
 *     { height: 8 }
 *   ]
 * };
 * ```
 */
export type LayoutElementProgress = Prettify<{
  /** Element type identifier */
  type: 'progress';
  /** Progress bar properties as array of property objects */
  properties: ProgressPropertyObject[];
}>;

/**
 * Timer element for displaying countdown or time information
 * @category Layout Elements
 * @description A timer element for showing countdown timers, relative time, or formatted dates with various display styles.
 * @example
 * ```typescript
 * const timerElement: LayoutElementTimer = {
 *   type: "timer",
 *   properties: [
 *     { endTime: Date.now() + 3600000 }, // 1 hour from now
 *     { style: "timer" },
 *     { fontSize: 16 },
 *     { color: "#ff0000" }
 *   ]
 * };
 * ```
 */
export type LayoutElementTimer = Prettify<{
  /** Element type identifier */
  type: 'timer';
  /** Timer properties as array of property objects */
  properties: TimerPropertyObject[];
}>;

export type LayoutElementChart = Prettify<{
  /** Element type identifier */
  type: 'chart';
  /** Chart properties as array of property objects */
  properties: ChartPropertyObject[];
}>;

/**
 * Chart-specific property objects
 * @category Property Objects
 * @description Properties specific to chart elements, including data series, styling, and chart type.
 * @extends BasePropertyObject
 */
type ChartPropertyObject =
  | BasePropertyObject
  /** @property type - Type of chart (e.g., "line", "bar", "pie") @example { type: "line" } */
  | { type: 'line' | 'bar' | 'pie' | 'area' | 'scatter' }
  /** @property data - Data series for the chart @example { data: [{ x: 1, y: 2 }, { x: 2, y: 3 }] } */
  | { data: { x: number; y: number }[] }
  /** @property width - Width of the chart @example { width: 300 } */
  | { width: number }
  /** @property height - Height of the chart @example { height: 200 } */
  | { height: number }
  /** @property color - Color of the chart lines/bars @example { color: "#007AFF" } */
  | { color: ColorString }
  /** @property fillColor - Fill color for area charts @example { fillColor: "#007AFF" } */
  | { fillColor: ColorString }
  /** @property strokeWidth - Width of the chart lines @example { strokeWidth: 2 } */
  | { strokeWidth: number }
  /** @property showPoints - Whether to show data points on the chart @example { showPoints: true } */
  | { showPoints: boolean }
  /** @property pointRadius - Radius of data points @example { pointRadius: 4 } */
  | { smooth: boolean }
  /** @property smooth - Whether to smooth the lines in line charts @example { smooth: true } */
  | { maxValue: number };

/**
 * Segmented Progress bar element for showing progress in segments
 * @category Layout Elements
 * @description A segmented progress bar element that displays progress divided into segments with customizable styling.
 * @example
 * ```typescript
 * const segmentedProgressElement: LayoutElementSegmentedProgress = {
 *   type: "segmented-progress",
 *   properties: [
 *     { segments: 5 },
 *     { filled: 3 },
 *     { spacing: 4 },
 *     { height: 6 },
 *     { cornerRadius: 3 },
 *     { filledColor: "#007AFF" },
 *     { unfilledColor: "#2C2C2E" },
 *     { strokeColor: "#FFFFFF" },
 *     { strokeDashed: true },
 *     { strokeWidth: 1 }
 *   ]
 * };
 * ```
 */
export type LayoutElementSegmentedProgress = Prettify<{
  /** Element type identifier */
  type: 'segmented-progress';
  /** Segmented progress bar properties as array of property objects */
  properties: SegmentedProgressPropertyObject[];
}>;

/**
 * Segmented-progress property objects
 * @category Property Objects
 * @description Properties specific to segmented progress bar elements, including segment count, filled segments, spacing, height, corner radius, and colors.
 * @extends BasePropertyObject
 */
type SegmentedProgressPropertyObject =
  | BasePropertyObject
  /** @property segments - Total number of segments in the progress bar @example { segments: 5 } */
  | { segments: number }
  /** @property filled - Number of filled segments @example { filled: 3 } */
  | { filled: number }
  /** @property spacing - Spacing between segments @example { spacing: 4 } */
  | { spacing: number }
  /** @property height - Height of the segmented progress bar @example { height: 6 } */
  | { height: number }
  /** @property cornerRadius - Corner radius for rounded corners @example { cornerRadius: 3 } */
  | { cornerRadius: number }
  /** @property filledColor - Color of filled segments @example { filledColor: "#007AFF" } */
  | { filledColor: ColorString }
  /** @property unfilledColor - Color of unfilled segments @example { unfilledColor: "#2C2C2E" } */
  | { unfilledColor: ColorString }
  /** @property strokeColor - Color of the segment stroke @example { strokeColor: "#FFFFFF" } */
  | { strokeColor: ColorString }
  /** @property strokeDashed - Whether the segment stroke is dashed @example { strokeDashed: true } */
  | { strokeDashed: boolean }
  /** @property strokeWidth - Width of the segment stroke @example { strokeWidth: 1 } */
  | { strokeWidth: number };

/**
 * Spacer-specific property objects
 * @category Property Objects
 * @description Properties specific to spacer elements.
 * @extends BasePropertyObject
 */
type SpacerPropertyObject =
  | BasePropertyObject
  /** @property minLength - Minimum spacing @example { minLength: 8 } */
  | { minLength: number };

/**
 * Gauge-specific property objects
 * @category Property Objects
 * @description Properties specific to gauge elements, including value configuration, angle settings, styling, and display options.
 * @extends BasePropertyObject
 */
type GaugePropertyObject =
  | BasePropertyObject
  /** @property value - Current value (required) @example { value: 75 } */
  | { value: number | string }
  /** @property minValue - Minimum value @example { minValue: 0 } */
  | { minValue: number }
  /** @property maxValue - Maximum value @example { maxValue: 100 } */
  | { maxValue: number }
  /** @property startAngle - Start angle in degrees @example { startAngle: -90 } */
  | { startAngle: number }
  /** @property endAngle - End angle in degrees @example { endAngle: 270 } */
  | { endAngle: number }
  /** @property strokeWidth - Line thickness @example { strokeWidth: 8 } */
  | { strokeWidth: number }
  /** @property foregroundColor - Progress color @example { foregroundColor: "#007AFF" } */
  | { foregroundColor: ColorString }
  /** @property backgroundColor - Track color @example { backgroundColor: "#E5E5EA" } */
  | { backgroundColor: ColorString }
  /** @property showsCurrentValueLabel - Show value text @example { showsCurrentValueLabel: true } */
  | { showsCurrentValueLabel: boolean };

/**
 * Spacer element for creating flexible spacing between elements
 * @category Layout Elements
 * @description A spacer element that creates flexible spacing with configurable minimum/maximum constraints and expansion priority.
 * @example
 * ```typescript
 * const spacerElement: LayoutElementSpacer = {
 *   type: "spacer",
 *   properties: [
 *     { minLength: 8 },
 *     { maxLength: 32 },
 *     { priority: "medium" }
 *   ]
 * };
 * ```
 */
export type LayoutElementSpacer = Prettify<{
  /** Element type identifier */
  type: 'spacer';
  /** Spacer properties as array of property objects */
  properties?: SpacerPropertyObject[];
}>;

/**
 * Gauge element for displaying circular progress indicators
 * @category Layout Elements
 * @description A gauge element that displays circular progress with customizable angles, colors, and value display options.
 * @example
 * ```typescript
 * const gaugeElement: LayoutElementGauge = {
 *   type: "gauge",
 *   properties: [
 *     { value: 75 },
 *     { minValue: 0 },
 *     { maxValue: 100 },
 *     { startAngle: -90 },
 *     { endAngle: 270 },
 *     { strokeWidth: 8 },
 *     { foregroundColor: "#30D158" },
 *     { backgroundColor: "#2C2C2E" },
 *     { showsCurrentValueLabel: true }
 *   ]
 * };
 * ```
 */
export type LayoutElementGauge = Prettify<{
  /** Element type identifier */
  type: 'gauge';
  /** Gauge properties as array of property objects */
  properties: GaugePropertyObject[];
}>;

/**
 * Dynamic Island layout configuration for different states
 */
export interface DynamicIslandLayout {
  /** Expanded state layout with multiple areas */
  expanded: {
    /** Leading area element */
    leading?: LayoutElement;
    /** Trailing area element */
    trailing?: LayoutElement;
    /** Center area element */
    center?: LayoutElement;
    /** Bottom area element */
    bottom?: LayoutElement;
  };
  /** Compact leading state configuration */
  compactLeading: LayoutElement;
  /** Compact trailing state configuration */
  compactTrailing: LayoutElement;
  /** Minimal state configuration */
  minimal: LayoutElement;
}
