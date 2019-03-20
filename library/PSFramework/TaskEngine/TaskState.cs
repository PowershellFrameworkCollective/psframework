namespace PSFramework.TaskEngine
{
    /// <summary>
    /// The state of the task or its previous execution
    /// </summary>
    public enum TaskState
    {
        /// <summary>
        /// Task is new, hasn't executed yet
        /// </summary>
        New,

        /// <summary>
        /// Task is currently running
        /// </summary>
        Running,

        /// <summary>
        /// Task has completed
        /// </summary>
        Completed,

        /// <summary>
        /// Task is pending another execution
        /// </summary>
        Pending,

        /// <summary>
        /// Task had an error
        /// </summary>
        Error
    }
}
