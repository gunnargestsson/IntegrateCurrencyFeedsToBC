codeunit 73404 "O4N Curr. Exch. Rate Secret"
{
    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Delete a secret from the isolation storage.
    /// </summary>
    /// <param name="SecretID">Parameter of type Guid.</param>
    [NonDebuggable]
    procedure DeleteSecret(SecretID: Guid)
    begin
        if HasSecret(SecretID) then
            IsolatedStorage.Delete(SecretID);
    end;

    /// <summary>
    /// Get a secret from the isolation storage
    /// </summary>
    /// <param name="SecretID">Parameter of type Guid.</param>
    [NonDebuggable]
    procedure GetSecret(SecretID: Guid) SecretText: Text
    begin
        if not IsolatedStorage.Get(SecretID, SecretText) then
            SecretText := '';
    end;

    /// <summary>
    /// Check if secret exists in isolation storage.
    /// </summary>
    /// <param name="SecretID">Parameter of type Guid.</param>
    /// <returns>Return variable "Boolean".</returns>
    [NonDebuggable]
    procedure HasSecret(SecretID: Guid): Boolean
    begin
        if IsNullGuid(SecretID) then exit(false);
        exit(IsolatedStorage.Contains(SecretID));
    end;

    /// <summary>
    /// Store a secret in isolation storage.
    /// </summary>
    /// <param name="SecretID">Parameter of type Guid.</param>
    /// <param name="SecretText">Parameter of type Text.</param>
    [NonDebuggable]
    procedure StoreSecret(var SecretID: Guid; SecretText: Text)
    begin
        if IsNullGuid(SecretID) then
            SecretID := CreateGuid();
        DeleteSecret(SecretID);
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(SecretID, SecretText)
        else
            IsolatedStorage.Set(SecretID, SecretText);
    end;
}