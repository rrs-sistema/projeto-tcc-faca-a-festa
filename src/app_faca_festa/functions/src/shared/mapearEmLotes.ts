/** Limita quantas operações independentes são iniciadas de cada vez. */
export async function mapearEmLotes<T, R>(
  itens: T[],
  executar: (item: T) => Promise<R>,
): Promise<R[]> {
  const resultados: R[] = [];
  const concorrencia = 8;
  for (let i = 0; i < itens.length; i += concorrencia) {
    resultados.push(...await Promise.all(itens.slice(i, i + concorrencia).map(executar)));
  }
  return resultados;
}
