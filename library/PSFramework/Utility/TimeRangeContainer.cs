using System;
using System.Collections.Generic;
using System.Linq;

namespace PSFramework.Utility
{
    /// <summary>
    /// A management wrapper handlign a series of TimeRanges.
    /// </summary>
    public class TimeRangeContainer
    {
        /// <summary>
        /// The stored time ranges
        /// </summary>
        public List<TimeRange> TimeRanges = new List<TimeRange>();

        /// <summary>
        /// Start a new time range
        /// </summary>
        /// <param name="Start">The starting point of the time range.</param>
        public void Start(DateTime Start)
        {
            TimeRanges.Add(new TimeRange(Start));
        }
        /// <summary>
        /// End the last open time range
        /// </summary>
        /// <param name="End">The end time of the time range</param>
        public void End(DateTime End)
        {
            if (TimeRanges.Count == 0)
                return;
            TimeRange found = TimeRanges.Where(o => o.End == DateTime.MinValue).Last();
            if (found != null)
                found.End = End;
        }
        /// <summary>
        /// Tests, whether the input is within any of the stored ranges.
        /// </summary>
        /// <param name="Timestamp">The timestamp to test for being in range.</param>
        /// <returns>Whether the timestamp actually is in any of the possible ranges.</returns>
        public bool IsInRange(DateTime Timestamp)
        {
            if (TimeRanges.Count == 0)
                return false;
            return TimeRanges.Where(o => o.IsInRange(Timestamp)).Count() > 0;
        }

        /// <summary>
        /// Removes all time ranges that have ended before the specified timestamp
        /// </summary>
        /// <param name="Timestamp">The delimiting timestamp</param>
        public void RemoveBefore(DateTime Timestamp)
        {
            if (TimeRanges.Count == 0)
                return;
            TimeRange[] victims = TimeRanges.Where(o => o.End > DateTime.MinValue && o.End < Timestamp).ToArray();
            foreach (TimeRange victim in victims)
                TimeRanges.Remove(victim);
        }
    }
}
