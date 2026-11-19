import {
  onCall as firebaseOnCall, CallableOptions, CallableRequest,
  CallableResponse, CallableFunction,
} from "firebase-functions/v2/https";
import { exigirMfaDaRequisicao } from "./politicaMfa";

// A verificação usa a sessão assinada pelo Firebase, inclusive no login Google.
export function onCall<T = any, R = any, S = unknown>(
  options: CallableOptions<T>,
  handler: (request: CallableRequest<T>, response?: CallableResponse<S>) => R | Promise<R>,
): CallableFunction<T, Promise<R>, S> {
  return firebaseOnCall<T, Promise<R>, S>(options, async (request, response) => {
    await exigirMfaDaRequisicao(request);
    return await handler(request, response);
  });
}
