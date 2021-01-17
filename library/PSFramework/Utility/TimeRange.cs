using System;

namespace PSFramework.Utility
{
    /// <summary>
    /// Container carrying a time range.
    /// </summary>
    public class TimeRange
    {
        /// <summary>
        /// The start time of the time range
        /// </summary>
        public DateTime Start;

        /// <summary>
        /// The end time of the time range
        /// </summary>
        public DateTime End;

        /// <summary>
        /// The total duration of the time range
        /// </summary>
        public TimeSpan Duration
        {
            get
            {
                if (Start == DateTime.MinValue && End != DateTime.MinValue)
                    return new TimeSpan(-1);
                if (Start != DateTime.MinValue && End == DateTime.MinValue)
                    return DateTime.Now - Start;
                return End - Start;
            }
        }

        /// <summary>
        /// Create an empty time range
        /// </summary>
        public TimeRange()
        {

        }
        /// <summary>
        /// Create a time range with the start filled in
        /// </summary>
        /// <param name="Start">The start time of the time range</param>
        public TimeRange(DateTime Start)
        {
            this.Start = Start;
        }

        /// <summary>
        /// Create a fully filled out time range
        /// </summary>
        /// <param name="Start">The start time of the time range</param>
        /// <param name="End">The end time of the time range</param>
        public TimeRange(DateTime Start, DateTime End)
        {
            this.Start = Start;
            this.End = End;
        }

        /// <summary>
        /// Checks whether a DateTime is within the defined start and end times.
        /// </summary>
        /// <param name="Timestamp">The timestamp to validate</param>
        /// <returns>Whether the timestamp is within the defined start and end times</returns>
        public bool IsInRange(DateTime Timestamp)
        {
            if (End == DateTime.MinValue)
                return Timestamp > Start;
            if (Start == DateTime.MinValue)
                return Timestamp < End;

            return Timestamp >= Start && Timestamp <= End;
        }
    }
}
