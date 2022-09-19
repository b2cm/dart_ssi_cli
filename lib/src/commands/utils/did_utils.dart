/// Checks if a did looks correctly
///
/// @todo this is only a stub -> implement me correctly
bool isValidDid(String maybeDid) {
  if (maybeDid.startsWith('did:')) {
    return true;
  }
  return false;
}
