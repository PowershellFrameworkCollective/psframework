using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using PSFramework.Parameter;

namespace PSFramework.Utility
{
    /// <summary>
    /// Class implementing a throttling mechanism / watcher
    /// </summary>
    public class Throttle
    {
        internal ConcurrentDictionary<Guid,ThrottleBase> _Throttles = new ConcurrentDictionary<Guid, ThrottleBase>();

        /// <summary>
        /// All throttling limits
        /// </summary>
        public ThrottleBase[] Limits => _Throttles.Values.ToArray();

        /// <summary>
        /// The maximum number of slots per interval
        /// </summary>
        public int Limit
        {
            get
            {
                ThrottleBase first = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleSet)).First();
                if (first != null)
                    return ((ThrottleSet)first).Limit;
                return 0;
            }
            set
            {
                ThrottleBase first = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleSet)).First();
                if (first != null)
                    ((ThrottleSet)first).Limit = value;
                else
                    _Throttles[Guid.NewGuid()] = new ThrottleSet(value, new TimeSpan(0, 0, 0));
            }
        }

        /// <summary>
        /// The interval over which slots are limited
        /// </summary>
        public TimeSpan Interval
        {
            get
            {
                ThrottleBase first = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleSet)).First();
                if (first != null)
                    return ((ThrottleSet)first).Interval;
                return new TimeSpan(0, 0, 0);
            }
            set
            {
                ThrottleBase first = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleSet)).First();
                if (first != null)
                    ((ThrottleSet)first).Interval = value;
                else
                    _Throttles[Guid.NewGuid()] = new ThrottleSet(1, value);
            }
        }

        /// <summary>
        /// The number of slots currently taken
        /// </summary>
        public int Count
        {
            get
            {
                ThrottleBase first = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleSet)).First();
                if (first == null)
                    return 0;
                return ((ThrottleSet)first).Count;
            }
        }

        /// <summary>
        /// DO not grant a slot before this timestamp has been reached.
        /// </summary>
        public DateTime NotBefore
        {
            get
            {
                ThrottleBase longest = _Throttles.Values.Where(o => o.GetType() == typeof(ThrottleTime)).OrderByDescending(o => ((ThrottleTime)o).NotBefore).First();
                if (longest != null)
                    return ((ThrottleTime)longest).NotBefore;
                return DateTime.MinValue;
            }
            set => _Throttles[Guid.NewGuid()] = new ThrottleTime(value, this);
        }

        /// <summary>
        /// Create a new throttle object
        /// </summary>
        public Throttle()
        {

        }

        /// <summary>
        /// Create a throttle object with a string DSL
        /// </summary>
        /// <param name="Setting">The setting string defining, how the throttling limits should be. Expects a whitespace-delimited set of COUNT/INTERVAL notations.</param>
        /// <exception cref="ArgumentException">Bad syntax gets punished</exception>
        public Throttle(string Setting)
        {
            foreach (string set in Setting.Split(' '))
            {
                if (!Regex.IsMatch(set, "^\\w+/\\w+"))
                    throw new ArgumentException($"Invalid throttle string: {Setting}", Setting);

                string[] parts = set.Split('/');
                try { _Throttles[Guid.NewGuid()] = new ThrottleSet(Int32.Parse(parts[0]), new TimeSpanParameter(parts[1])); }
                catch { throw new ArgumentException($"Invalid throttle string: {Setting}", Setting); }
            }
        }

        /// <summary>
        /// Create a new throttle object
        /// </summary>
        /// <param name="Limit">How many slots are available per interval?</param>
        /// <param name="Interval">hat is the interval over which slots are measured?</param>
        public Throttle(int Limit, TimeSpanParameter Interval)
        {
            _Throttles[Guid.NewGuid()] = new ThrottleSet(Limit, Interval);
        }

        /// <summary>
        /// Obtain an execution slots from the throttle
        /// </summary>
        /// <param name="Timeout">How long are you willing to wait for a slot before giving up?</param>
        public void GetSlot(TimeSpanParameter Timeout = null)
        {
            foreach (ThrottleBase entry in _Throttles.Values)
                entry.GetSlot(Timeout);
        }

        /// <summary>
        /// Clean up all throttle sets
        /// </summary>
        public void Purge()
        {
            foreach (ThrottleBase entry in _Throttles.Values)
                entry.Purge();
        }

        /// <summary>
        /// Resets all throttling limits
        /// </summary>
        public void Reset()
        {
            foreach (ThrottleBase entry in _Throttles.Values)
                entry.Reset();
        }

        /// <summary>
        /// Removes a limit from the throttle
        /// </summary>
        /// <param name="Limit">The limit to remove</param>
        public void RemoveLimit(ThrottleBase Limit)
        {
            KeyValuePair<Guid, ThrottleBase> key = _Throttles.Where(o => o.Value == Limit).First();
            if (key.Key != null)
                _Throttles.TryRemove(key.Key, out _);
        }

        /// <summary>
        /// Add a limit to the throttle
        /// </summary>
        /// <param name="Limit">A pre-created limit to add</param>
        public void AddLimit(ThrottleBase Limit)
        {
            _Throttles[Guid.NewGuid()] = Limit;
        }

        /// <summary>
        /// Add a throttle control, limiting executions within a given timespan
        /// </summary>
        /// <param name="Interval">The timespan within which executions are counted</param>
        /// <param name="Count">The number of action slots within the specified interval</param>
        public void AddLimit(TimeSpanParameter Interval, int Count)
        {
            _Throttles[Guid.NewGuid()] = new ThrottleSet(Count, Interval);
        }

        /// <summary>
        /// Add a throttle control, blocking any further executions until the specified time has come to pass.
        /// </summary>
        /// <param name="Timeout">Time until when no further action should take place</param>
        public void AddLimit(DateTimeParameter Timeout)
        {
            _Throttles[Guid.NewGuid()] = new ThrottleTime(Timeout, this);
        }
    }
}
