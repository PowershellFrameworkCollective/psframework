using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Caching
{
    /// <summary>
    /// A cache entry
    /// </summary>
    public class CachedData : IDisposable
    {
        #region Constructors
        /// <summary>
        /// Create a new cache entry
        /// </summary>
        /// <param name="Parent">The cache the item belongs to</param>
        /// <param name="Key">The key the data is stored under</param>
        /// <param name="Value">The value being cached</param>
        /// <exception cref="ArgumentNullException">If either Parent or Key are left null, errors happen.</exception>
        public CachedData(CacheBase Parent, object Key, object Value)
        {
            if (null == Parent)
                throw new ArgumentNullException("Parent");
            if (null == Key)
                throw new ArgumentNullException("Key");

            _Parent = Parent;
            this.Key = Key;
            _Value = Value;
            Timestamp = DateTime.Now;
            MoveNew();
        }
        #endregion Constructors

        /// <summary>
        /// The value being cached
        /// </summary>
        public object Value
        {
            get
            {
                if (null == _Value)
                    return null;

                if (IsExpired)
                {
                    lock (_Lock)
                    {
                        _Value = null;
                    }
                    return _Value;
                }

                return _Value;
            }
            set
            {
                lock (_Lock)
                {
                    Timestamp = DateTime.Now;
                    _Value = value;
                    MoveToLatest();
                }
            }
        }
        private object _Value;

        /// <summary>
        /// When was the last time the value was updated
        /// </summary>
        public DateTime Timestamp { private set; get; }
        
        /// <summary>
        /// The key the data is stored under
        /// </summary>
        public object Key { private set; get; }

        private object _Lock = 42;

        private CacheBase _Parent;

        /// <summary>
        /// Is the value expired?
        /// </summary>
        public bool IsExpired
        {
            get
            {
                if (null == _Parent)
                    return true;
                if (_Parent.Lifetime == null || _Parent.Lifetime.Value.TotalSeconds < 1)
                    return false;
                return Timestamp.Add(_Parent.Lifetime) < DateTime.Now;
            }
        }

        /// <summary>
        /// Kill the value
        /// </summary>
        public void Dispose()
        {
            lock (_Lock)
            {
                MoveUnlist();
                if (null != _Parent)
                {
                    _Parent.RemoveInt(Key);
                    if (_Parent.TryDispose && _Value is IDisposable)
                        ((IDisposable)_Value).Dispose();
                }
                _Value = null;
            }
        }

        /// <summary>
        /// Kill the value if still expired
        /// </summary>
        internal void DisposeIfExpired()
        {
            lock (_Lock)
            {
                if (!IsExpired)
                    return;

                MoveUnlist();
                if (null != _Parent)
                {
                    _Parent.RemoveInt(Key);
                    if (_Parent.TryDispose && _Value is IDisposable)
                        ((IDisposable)_Value).Dispose();
                }
                _Value = null;
            }
        }

        /// <summary>
        /// Text display of the value
        /// </summary>
        /// <returns>THe valoue contained</returns>
        public override string ToString()
        {
            if (IsExpired)
                return "<Expired>";
            if (null == Value)
                return "<Empty>";
            return Value.ToString();
        }

        #region Order
        /// <summary>
        /// The item that comes after
        /// </summary>
        public CachedData Next;
        /// <summary>
        /// The item that comes next
        /// </summary>
        public CachedData Previous;

        /// <summary>
        /// Make the current entry the latest entry in the Cache
        /// </summary>
        internal void MoveToLatest()
        {
            lock (_Parent._OrderLock)
            {
                // Case: Is already the last
                if (_Parent.Newest == this)
                    return;

                // Case: Is the only element
                if (_Parent.Newest == null && _Parent.Oldest == null)
                {
                    _Parent.Oldest = this;
                    _Parent.Newest = this;
                    Next = null;
                    Previous = null;
                    return;
                }

                if (Next != null)
                    Next.Previous = Previous;
                if (Previous != null)
                    Previous.Next = Next;
                if (_Parent.Oldest == this)
                    _Parent.Oldest = Next;

                Next = null;
                Previous = _Parent.Newest;
                if (_Parent.Newest != null)
                    _Parent.Newest.Next = this;
                _Parent.Newest = this;
            }
        }

        /// <summary>
        /// Adds the current entry as the latest entry
        /// </summary>
        internal void MoveNew()
        {
            lock (_Parent._OrderLock)
            {
                if (_Parent.Newest != null)
                {
                    _Parent.Newest.Next = this;
                    Previous = _Parent.Newest;
                }
                _Parent.Newest = this;
                if (_Parent.Oldest == null)
                    _Parent.Oldest = this;
            }
        }

        /// <summary>
        /// Removes item from the chain of order.
        /// Should only be called after removing it from the cache itself.
        /// </summary>
        internal void MoveUnlist()
        {
            lock (_Parent._OrderLock)
            {
                MoveUnlistNoLock();
            }
        }
        /// <summary>
        /// Removes item from the chain of order.
        /// Does not perform locking, so it is not be threadsafe.
        /// Should only be called after removing it from the cache itself.
        /// </summary>
        internal void MoveUnlistNoLock()
        {
            if (Next != null)
                Next.Previous = Previous;
            if (Previous != null)
                Previous.Next = Next;
            if (_Parent.Oldest == this)
                _Parent.Oldest = Next;
            if (_Parent.Newest == this)
                _Parent.Newest = Previous;
        }
        #endregion Order
    }
}
