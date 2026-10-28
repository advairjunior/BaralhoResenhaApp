using System.Globalization;
using System.Text.RegularExpressions;

namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Termine a frase: a carta dá o começo e cada um completa em segredo. Quando
/// todo mundo escreveu, as frases aparecem embaralhadas e sem autor e a turma
/// vota na melhor. Só a vencedora revela quem escreveu; as outras ficam anônimas.
/// </summary>
public sealed partial class Sala
{
    /// <summary>O dobro do bilhete do Correio: dá para uma piada, não para um textão.</summary>
    internal const int TamanhoDaFrase = 40;

    private void EscreverFrase(Rodada rodada, Jogador jogador, string resposta)
    {
        var frase = Regex.Replace(resposta ?? string.Empty, @"\s+", " ").Trim();
        if (frase.Length == 0)
            throw new AcaoNaoPermitidaException("Escreva o fim da frase.");
        // Emoji conta como uma letra: é o que a pessoa vê na tela.
        if (new StringInfo(frase).LengthInTextElements > TamanhoDaFrase)
            throw new AcaoNaoPermitidaException($"Frase curta: até {TamanhoDaFrase} letras.");
        rodada.Frases[jogador.Id] = frase;
        ComecarVotacaoSeTodosEscreveram(rodada);
    }

    private void ComecarVotacaoSeTodosEscreveram(Rodada rodada)
    {
        if (rodada.Escrevendo && rodada.Frases.Count >= 2 && NaMesa.All(j => rodada.Frases.ContainsKey(j.Id)))
            ComecarVotacaoDasFrases(rodada);
    }

    /// <summary>Embaralha para a ordem não entregar ninguém.</summary>
    private void ComecarVotacaoDasFrases(Rodada rodada) =>
        rodada.OrdemDasFrases = rodada.Frases.Keys.OrderBy(_ => _sorteio.Next()).ToList();

    private static void ValidarVotoNaFrase(Rodada rodada, Jogador jogador, string resposta)
    {
        var ordem = rodada.OrdemDasFrases!;
        if (!int.TryParse(resposta, out var indice) || indice < 0 || indice >= ordem.Count)
            throw new AcaoNaoPermitidaException("Vote numa das frases.");
        if (ordem[indice] == jogador.Id)
            throw new AcaoNaoPermitidaException("Não vale votar na sua.");
    }

    /// <summary>As frases como a mesa vê na votação: só o texto.</summary>
    internal static IReadOnlyList<string> FrasesParaVotar(Rodada rodada) =>
        rodada.OrdemDasFrases?.Select(autor => rodada.Frases[autor]).ToList() ?? [];

    /// <summary>
    /// Quem escreveu a mais votada (empate: todas as mais votadas) distribui goles
    /// e ganha uma carta na manga, como no elogio. Ninguém bebe por ter perdido.
    /// </summary>
    private Revelacao RevelarFrases(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var ordem = rodada.OrdemDasFrases ?? [];
        var votos = ordem.Select((_, indice) => respostas.Count(r => r.Value == indice.ToString())).ToList();
        var maximo = votos.Count > 0 ? votos.Max() : 0;
        var vencedores = maximo == 0
            ? []
            : ordem.Where((autor, indice) => votos[indice] == maximo && _jogadores.Any(j => j.Id == autor)).ToList();
        foreach (var vencedor in _jogadores.Where(j => vencedores.Contains(j.Id))) DarCarta(vencedor);

        var frases = ordem
            .Select((autor, indice) => new FraseRevelada(
                rodada.Frases[autor], votos[indice], vencedores.Contains(autor) ? autor : null))
            .OrderByDescending(f => f.Votos)
            .ToList();
        return new Revelacao([], [], [], [], null, Elogio: true)
        {
            Escolhidos = vencedores,
            Frases = frases,
        };
    }
}
