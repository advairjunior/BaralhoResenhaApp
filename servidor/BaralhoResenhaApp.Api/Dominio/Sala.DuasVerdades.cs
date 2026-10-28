using System.Globalization;
using System.Text.RegularExpressions;

namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Duas verdades e uma mentira: a pessoa da vez (o {jogador} da carta, pelo
/// rodízio) escreve três frases sobre si e marca a mentira. A turma vota em
/// segredo em qual é. Quem errou leva ponto; se ninguém acertou, a pessoa da
/// vez distribui goles.
/// </summary>
public sealed partial class Sala
{
    /// <summary>Uma frase de verdade (ou de mentira), não uma história.</summary>
    internal const int TamanhoDaAfirmacao = 60;

    public void EscreverDuasVerdades(string token, int numeroDaRodada, IReadOnlyList<string> frases, int mentira)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo != ModoDeJogo.DuasVerdades)
                throw new AcaoNaoPermitidaException("Só vale no Duas verdades e uma mentira.");
            if (jogador.Id != rodada.Alvo)
                throw new AcaoNaoPermitidaException($"Quem escreve é {NomeDaVez(rodada)}.");
            if (rodada.Afirmacoes.Count > 0)
                throw new AcaoNaoPermitidaException("As frases já estão na mesa.");
            if (frases is not { Count: 3 })
                throw new AcaoNaoPermitidaException("Escreva três frases: duas verdades e uma mentira.");
            var limpas = frases.Select(f => Regex.Replace(f ?? string.Empty, @"\s+", " ").Trim()).ToList();
            if (limpas.Any(f => f.Length == 0))
                throw new AcaoNaoPermitidaException("Escreva as três frases.");
            if (limpas.Any(f => new StringInfo(f).LengthInTextElements > TamanhoDaAfirmacao))
                throw new AcaoNaoPermitidaException($"Frase curta: até {TamanhoDaAfirmacao} letras cada.");
            if (mentira is < 0 or > 2)
                throw new AcaoNaoPermitidaException("Marque qual das três é a mentira.");
            rodada.Afirmacoes = limpas;
            rodada.Mentira = mentira;
            Tocar();
        }
    }

    private string NomeDaVez(Rodada rodada) =>
        _jogadores.FirstOrDefault(j => j.Id == rodada.Alvo)?.Nome ?? "a pessoa da vez";

    private void ExigirAfirmacoes(Rodada rodada)
    {
        if (rodada.Afirmacoes.Count == 0)
            throw new AcaoNaoPermitidaException($"Espere {NomeDaVez(rodada)} escrever as três frases.");
    }

    private void ValidarVotoNaMentira(Rodada rodada, Jogador jogador, string resposta)
    {
        ExigirAfirmacoes(rodada);
        if (jogador.Id == rodada.Alvo)
            throw new AcaoNaoPermitidaException("As frases são suas: espere a turma votar.");
        if (resposta is not ("0" or "1" or "2"))
            throw new AcaoNaoPermitidaException("Vote numa das três frases.");
    }

    /// <summary>
    /// Quem errou leva ponto. Ninguém acertou: a pessoa da vez enganou a turma
    /// inteira, distribui goles (como no elogio) e conta para o prêmio.
    /// </summary>
    private Revelacao RevelarMentira(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var mentira = rodada.Mentira!.Value.ToString();
        var acertaram = respostas.Where(r => r.Value == mentira).Select(r => r.Key).ToList();
        var erraram = respostas.Where(r => r.Value != mentira).Select(r => r.Key).ToList();
        var daVez = _jogadores.FirstOrDefault(j => j.Id == rodada.Alvo);
        var enganouTodos = daVez is not null && acertaram.Count == 0 && erraram.Count > 0;
        if (enganouTodos) daVez!.Estatisticas.MentirasPerfeitas++;
        return new Revelacao([], [], [], erraram, null, Elogio: enganouTodos)
        {
            Escolhidos = enganouTodos ? [daVez!.Id] : [],
            Mentira = rodada.Mentira,
            VotosNasAfirmacoes = Enumerable.Range(0, 3).Select(i => respostas.Count(r => r.Value == i.ToString())).ToList(),
            Acertaram = acertaram,
        };
    }
}
