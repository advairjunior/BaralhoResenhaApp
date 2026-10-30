namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// 🧃 Sala sem álcool: o cofrinho continua, mas quando enche sai uma prenda no
/// lugar do gole; a dose ("bebe 2") vira uma prenda por gole. Quem a turma
/// escolhe no elogio passa uma prenda para alguém, no lugar de distribuir goles.
/// </summary>
public sealed partial class Sala
{
    /// <summary>
    /// Quem só junta pontos: marcou "sem álcool" numa sala com bebida. Na sala sem
    /// álcool todo mundo é igual e paga prenda.
    /// </summary>
    internal bool SoPontos(Jogador jogador) => jogador.SemAlcool && !Configuracao.SemAlcool;

    /// <summary>
    /// As prendas de cada um nesta carta. Sorteadas na primeira vez que alguém
    /// olha e guardadas na rodada: a prenda não muda de uma consulta para outra.
    /// </summary>
    internal IReadOnlyDictionary<Guid, IReadOnlyList<string>> PrendasDaCarta(Rodada rodada)
    {
        if (!Configuracao.SemAlcool) return new Dictionary<Guid, IReadOnlyList<string>>();
        var prendas = new Dictionary<Guid, IReadOnlyList<string>>();
        foreach (var id in rodada.BebemAgora)
        {
            var quantas = (rodada.EncheuCofrinho.Contains(id) ? 1 : 0) +
                (rodada.Contas.TryGetValue(id, out var conta) ? conta.Goles : 0);
            if (!rodada.Prendas.TryGetValue(id, out var sorteadas))
                rodada.Prendas[id] = sorteadas = [];
            if (sorteadas.Count < quantas) sorteadas.AddRange(SortearPrendas(rodada, quantas - sorteadas.Count));
            prendas[id] = sorteadas.Take(quantas).ToList();
        }
        return prendas;
    }

    /// <summary>Elogio na sala sem álcool: quem a turma escolheu passa esta prenda para alguém.</summary>
    internal string? PrendaParaDar(Rodada rodada)
    {
        if (!Configuracao.SemAlcool || Fase != FaseDaSala.Revelada ||
            rodada.Revelacao is not { Elogio: true, Escolhidos.Count: > 0 })
            return null;
        return rodada.PrendaDoElogio ??= SortearPrendas(rodada, 1)[0];
    }

    private List<string> SortearPrendas(Rodada rodada, int quantas) =>
        Sortear(_baralho.Prendas.Ate(Configuracao.NivelNaCarta(rodada.Numero - 1)), quantas);
}
