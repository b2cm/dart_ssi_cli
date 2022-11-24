import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';

class DidCommVerifyPresentationCommand extends SsiCliCommandBase {


  @override
  final name = VERIFY_PRESENTATION;

  @override
  final description =
      "Verifies if a presentation is a presentation is\n"
      " - (i) cryptographically valid\n"
      " - (ii) satisfying the request"
  ;

  DidCommVerifyPresentationCommand() {
    addWalletNecessaryParametersToArgParser(argParser);

    argParser
        ..addOption(
          PARAM_PRESENTATION_REQUEST,
          help: "JSON: Presentation request that needs to be satisfied.",
        )

        ..addOption(
          PARAM_PRESENTATION,
          help: "JSON: Presentation that needs to be verified.",
        )
    ;
  }

  @override
  run() async {
    var presentationMap = getArgJson(PARAM_PRESENTATION)!;
    var presentationRequestMap = getArgJson(PARAM_PRESENTATION_REQUEST)!;

    var wallet = await loadWalletFromArgs();

    Presentation? presentation;
    try {
      presentation = Presentation.fromJson(presentationMap);
    } catch (e) {
      writeError("Presentation could not be parsed due to `${e.toString()}`",
          94855333, terminate: true);
    }

    RequestPresentation? presentationRequest;
    try {
      presentationRequest = RequestPresentation.fromJson(presentationRequestMap);
    } catch (e) {
      writeError("Presentation definition could not be parsed due to "
          "`${e.toString()}`",
          49583490, terminate: true);
    }

    var challenge = presentationRequest!.presentationDefinition.first.challenge;
    var vp = presentation!.verifiablePresentation.first;

    // (i) verify if the presentation is cryptographically valid
    try {
      var verified = await verifyPresentation(vp, challenge);
      if (!verified) {
        writeError("Presentation could not be verified", 423823094,
            terminate: true);
      }
    } catch (e) {
      writeError("Presentation could not be verified due to `${e.toString()}`",
          9385734895, terminate: true);
    }

    // (ii) verify if the presentation satisfies the request
    var definition = presentationRequest.presentationDefinition
        .first.presentationDefinition;

    var collectedVCs = <VerifiableCredential>[];
    presentation.verifiablePresentation.forEach((VerifiablePresentation element) {
      collectedVCs.addAll(element.verifiableCredential);
    });

    var vcMap = collectedVCs.map((e) => e.toJson()).toList();
    try {
         searchCredentialsForPresentationDefinition(vcMap, definition);
    } catch(e) {
      writeError("Presentation does not satisfy the request due to `${e.toString()}`",
          5380934, terminate: true);
    }
    writeResult("true");
  }
}
