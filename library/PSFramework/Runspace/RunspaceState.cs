namespace PSFramework.Runspace
{
    /// <summary>
    /// Contains the state a managed, unique runspace can be in.
    /// </summary>
    public enum PsfRunspaceState
    {
        /// <summary>
        /// The runspace is up and running
        /// </summary>
        Running = 1,

        /// <summary>
        /// The runspace has received the stop order, but has not yet obeyed it
        /// </summary>
        Stopping = 2,

        /// <summary>
        /// The runspace has followed its order to stop and is currently disabled
        /// </summary>
        Stopped = 3,

        /// <summary>
        /// The runspace crashed and burned. It is also stopped without fracefully closing out, check the Errors property.
        /// </summary>
        Failed = 4
    }
}
