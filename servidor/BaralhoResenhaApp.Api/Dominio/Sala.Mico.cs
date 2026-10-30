namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>🤡 Mico da noite: quem paga, as três opções e o voto de cada um da turma.</summary>
public sealed class MicoDaNoite
{
    public const int Opcoes = 3;

    public required IReadOnlyList<Guid> Pagadores { get; init; }
    public required IReadOnlyList<string> Micos { get; init; }
    public Dictionary<Guid, int> Votos { get; } = [];
    public int? Escolhido { get; set; }
}

/// <param name="Votos">Votos em cada opção; vazio até a turma escolher, para ninguém ir atrás da maioria.</param>
/// <param name="Eleitores">Quantos votam: a turma na mesa, menos quem paga.</param>
public sealed record MicoVisivel(
    IReadOnlyList<Guid> Pagadores,
    IReadOnlyList<string> Opcoes,
    int Votaram,
    int Eleitores,
    int? MeuVoto,
    int? Escolhido,
    IReadOnlyList<int> Votos);

/// <summary>
/// Na sala sem álcool, a noite termina com um mico: quem fechou com mais pontos
/// paga, e a turma escolhe qual entre três. Empate no topo paga junto.
/// </summary>
public sealed partial class Sala
{
    public MicoDaNoite? Mico { get; private set; }

    private void SortearOMico()
    {
        Mico = null;
        if (!Configuracao.SemAlcool || _jogadores.Count == 0) return;
        var maximo = _jogadores.Max(j => j.Pontos);
        if (maximo == 0) return;
        Mico = new MicoDaNoite
        {
            Pagadores = _jogadores.Where(j => j.Pontos == maximo).Select(j => j.Id).ToList(),
            Micos = _baralho.Prendas.Micos.OrderBy(_ => _sorteio.Next()).Take(MicoDaNoite.Opcoes).ToList(),
        };
        // Todo mundo empatado no topo: não sobra quem vote, a sorte escolhe.
        if (!Eleitores(Mico).Any()) Mico.Escolhido = _sorteio.Next(Mico.Micos.Count);
    }

    private IEnumerable<Jogador> Eleitores(MicoDaNoite mico) => NaMesa.Where(j => !mico.Pagadores.Contains(j.Id));

    public void VotarNoMico(string token, int opcao)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (Fase != FaseDaSala.Fim || Mico is not { } mico)
                throw new AcaoNaoPermitidaException("Não tem mico para votar.");
            if (mico.Escolhido is not null) throw new AcaoNaoPermitidaException("A turma já escolheu o mico.");
            if (mico.Pagadores.Contains(jogador.Id)) throw new AcaoNaoPermitidaException("Quem paga o mico não vota.");
            if (opcao < 0 || opcao >= mico.Micos.Count) throw new AcaoNaoPermitidaException("Esse mico não está na lista.");
            mico.Votos[jogador.Id] = opcao;
            if (Eleitores(mico).All(j => mico.Votos.ContainsKey(j.Id)))
            {
                var contagem = ContarVotos(mico);
                var empatados = Enumerable.Range(0, contagem.Count).Where(i => contagem[i] == contagem.Max()).ToList();
                mico.Escolhido = empatados[_sorteio.Next(empatados.Count)];
            }
            Tocar();
        }
    }

    private static List<int> ContarVotos(MicoDaNoite mico) =>
        Enumerable.Range(0, mico.Micos.Count).Select(i => mico.Votos.Values.Count(v => v == i)).ToList();

    internal MicoVisivel? MicoPara(Jogador eu) => Fase != FaseDaSala.Fim || Mico is not { } mico
        ? null
        : new MicoVisivel(
            mico.Pagadores,
            mico.Micos,
            mico.Votos.Count,
            Eleitores(mico).Count(),
            mico.Votos.TryGetValue(eu.Id, out var voto) ? voto : null,
            mico.Escolhido,
            mico.Escolhido is null ? [] : ContarVotos(mico));
}
